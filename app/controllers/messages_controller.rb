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
    @entry = Entry.find(params[:entry]) unless params[:entry].blank?
    @message.create_message(current_user, params[:msg_type], params[:open], params[:receiver], params[:receiver_company], @entry)
    
    respond_to do |format|
      if current_user.has_role?('admin')
        @priv_messages = @entry.messages.closed
      else
        @priv_messages = @entry.messages.closed.restricted(current_user.company)
      end
      @pub_messages = @entry.messages.open

      if current_user.messages << @message
        format.html { redirect_to session['referer'], :notice => "Successfully created message."; session['referer'] = nil }
        format.js { flash.now[:notice] = "Successfully created message." }
        MessageMailer.delay.message_alert(@entry, @message)
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
    # TODO: make js
    @message = Message.find(params[:id])
    @message.destroy
    respond_to  do |format|
      format.html { redirect_to :back, :notice => "Deleted message." }# redirect_to messages_url, :notice => "Successfully destroyed message."
      format.js { flash.now[:notice] = "Message deleted." }
    end
  end
end
