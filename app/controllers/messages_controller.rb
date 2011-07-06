class MessagesController < ApplicationController
  def index
    @messages = Message.scoped
    @message = Message.new
  end

  def show
    @message = Message.find(params[:id])
  end
  
  def show_fields
    @message = current_user.messages.build(:parent_id => params[:parent_id])
    # @msg_to = params[:msg_to]
    @msg_type = params[:msg_type]
    @entry = params[:entry]
  end
  
  def cancel
    @entry = Entry.find(params[:entry])
    respond_to do |format| 
      format.html { redirect_to :back }
      format.js 
    end
  end

  def new
    session['referer'] = request.env["HTTP_REFERER"]
    @message = Message.new(:parent_id => params[:parent_id])
  end

  def create
    # raise params.to_yaml
    @message = current_user.messages.build(params[:message])
    @message.user_company_id = current_user.company.id
    @message.user_type = current_user.roles.first.name
    @entry = Entry.find(params[:entry]) unless params[:entry].blank?
    @message.entry_id = @entry.id unless params[:entry].blank?
    if params[:msg_type] == 'admin'
      @message.receiver_id = 1
      @message.receiver_company_id = 1
      @message.open = params[:open] unless params[:open].blank?
    elsif params[:msg_type] == 'buyer'
      @message.receiver_id = @entry.user_id
      @message.receiver_company_id = @entry.company_id
      @message.open = params[:open] unless params[:open].blank?
    elsif params[:msg_type] == 'seller'
      @message.receiver_id = params[:receiver]
      @message.receiver_company_id = params[:receiver_company]
      @message.open = params[:open] unless params[:open].blank?
    elsif params[:msg_type] == 'public'
      @message.open = true
    end

    if current_user.has_role?('admin')
      @priv_messages = @entry.messages.closed
    else
      @priv_messages = @entry.messages.closed.restricted(current_user.company)
    end
    @pub_messages = @entry.messages.open
    
    respond_to do |format|
      if current_user.messages << @message
        format.html { redirect_to session['referer'], :notice => "Successfully created message."; session['referer'] = nil }
        format.js { flash.now[:notice] = "Successfully created message." }
      else
        format.html { render :action => 'new' }
        format.js { flash.now[:notice] = "Message was not sent. Try again!" }
      end
    end      
  end

  def edit
    session['referer'] = request.env["HTTP_REFERER"]
    @message = Message.find(params[:id])
    @entry = params[:entry]
    render :action => "show_fields"
  end

  def update
    @message = Message.find(params[:id])

    @entry = Entry.find(params[:entry]) unless params[:entry].blank?
    if current_user.has_role?('admin')
      @priv_messages = @entry.messages.closed
    else
      @priv_messages = @entry.messages.closed.restricted(current_user.company)
    end
    @pub_messages = @entry.messages.open
    
    respond_to do |format|
      if @message.update_attributes(params[:message])
        format.html { redirect_to session['referer'], :notice => "Successfully updated  message."; session['referer'] = nil }
        format.js { flash.now[:notice] = "Successfully updated message." }
      else
        format.html { render :action => 'edit' }
        format.js { flash.now[:notice] = "Message was not updated. Try again!" }
      end
    end      
 end

  def destroy
    @message = Message.find(params[:id])
    @message.destroy
    redirect_to messages_url, :notice => "Successfully destroyed message."
  end
end
