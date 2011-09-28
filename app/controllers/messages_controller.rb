class MessagesController < ApplicationController
  def index
    @messages = Message.order('created_at desc').paginate(:page => params[:page], :per_page => 20)
  end

  def show
    @message = Message.find(params[:id])
  end
  
  def show_fields
    @message = current_user.messages.build(:parent_id => params[:parent_id])
    @msg_type = params[:msg_type]
    @entry = params[:entry]
    @order = params[:order] if params[:order]
  end
  
  def cancel
    @entry = Entry.find(params[:entry])
    @order = Order.find(params[:order]) unless params[:order].blank?
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
    @order = Order.find(params[:order]) unless params[:order].blank?
    @message.create_message(current_user, params[:msg_type], params[:open], params[:receiver], params[:receiver_company], @entry, @order)
    
    unless request.env["HTTP_REFERER"] == new_message_url
      respond_to do |format|
        initialize_messages
        if current_user.messages << @message
          format.html { redirect_to session['referer'], :notice => "Successfully created message."; session['referer'] = nil }
          format.js { flash.now[:notice] = "Successfully created message." }
          MessageMailer.delay.message_alert(@entry, @message)
        else
          format.html { render :action => 'new' }
          format.js { flash.now[:notice] = "Message was not sent. Try again!" }
        end
      end    
    else
      current_user.messages << @message
      redirect_to session['referer'], :notice => "Successfully created message."
    end
  end

  def edit
    session['referer'] = request.env["HTTP_REFERER"]
    @message = Message.find(params[:id])
    @entry = params[:entry]
    @order = params[:order] if params[:order]
    respond_to do |format|
      format.html { render :edit }
      format.js { render :action => "show_fields"}
    end
  end

  def update
    @message = Message.find(params[:id])
    @entry = Entry.find(params[:entry]) unless params[:entry].blank?
    @order = Order.find(params[:order]) unless params[:order].blank?

    unless  request.env["HTTP_REFERER"] == edit_message_url(@message)
      initialize_messages
      respond_to do |format|
        if @message.update_attributes(params[:message])
          format.html { redirect_to session['referer'], :notice => "Successfully updated  message."; session['referer'] = nil }
          format.js { flash.now[:notice] = "Successfully updated message." }
        else
          format.html { render :action => 'edit' }
          format.js { flash.now[:notice] = "Message was not updated. Try again!" }
        end
      end      
    else
      @message.update_attributes(params[:message])
      redirect_to session['referer'], :notice => "Successfully updated message."
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
  
  private
  
  def initialize_messages
    if @order.present?
      if current_user.has_role?('admin')
        @priv_messages = @order.messages
      else
        @priv_messages = @order.messages.closed.restricted(current_user.company)
      end
    else
      if current_user.has_role?('admin')
        @priv_messages = @entry.messages.closed
      else
        @priv_messages = @entry.messages.closed.restricted(current_user.company)
      end
      @pub_messages = @entry.messages.open
    end
  end
end
