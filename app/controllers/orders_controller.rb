class OrdersController < ApplicationController
  include ActionView::Helpers::TagHelper
  
  def index
  end

  def create
    @bids = Bid.where(:id => params[:bids])
    @bid_users = @bids.collect(&:user_id).uniq
    @entry = Entry.find(params[:entry_id])
    @client_ip = request.remote_ip
    
    @orders = Array.new
    
    # Create a unique PO per seller
    @bid_users.each do |bid_user|
      @order = current_user.orders.build(params[:order])
      user_bids = @bids.where(:user_id => bid_user)
      @order.initialize_order(current_user, user_bids, bid_user, @client_ip)
      @orders << @order
    end 

    if @orders.all?(&:valid?) 
      @entry.orders << @orders 
      @bids.each do |bid|
        @line_item = LineItem.find(bid.line_item_id)
        bid.order_process(@line_item)
      end
      @entry.update_status unless @entry.buyer_status == 'Relisted'
      # @orders.each { |order| OrderMailer.delay.order_alert(order) }
      unless @orders.count < 2
        flash[:notice] = "Your POs have been released and will be processed right away.<br>
          Your suppliers are #{content_tag :strong, @orders.collect{ |o| o.seller.profile.company.name }.to_sentence}. Thanks!".html_safe
        redirect_to @entry 
      else
        flash[:notice] = ("Your PO has been released and will be processed right away.<br> 
          Your supplier is #{content_tag :strong, @order.seller.profile.company.name}. Thanks!").html_safe
        redirect_to @order
      end
    else
      @order.seller_id = nil #This hides seller's name again, since PO is not yet released
      flash[:error] = ("There was a problem releasing your PO.<br> <strong>Is required info complete?</strong>").html_safe
      render 'bids/accept'
    end
  end

  def edit
    session['referer'] = request.env["HTTP_REFERER"]
    find_order_and_entry
    @buyer_companies = Company.where(:primary_role => 2).includes(:users)
    @seller_companies = Company.where(:primary_role => 3).includes(:users)
  end
  
  def update
    find_order_and_entry
    if @order.update_attributes(params[:order])
      redirect_to session['referer'], :notice => 'Updated the PO.' 
      session['referer'] = nil
    else
      flash[:error] = "Unable to update PO."
      render 'edit'
    end 
      
  end

  def show
    find_order_and_entry
    # @order_items = @order.order_items
    @order_items1 = @order.bids
    initialize_messages
  end

  def print
    find_order_and_entry
    @order_items1 = @order.bids.not_cancelled
    initialize_messages
    render :layout => 'print'
  end

  def confirm # For seller to confirm PO
    find_order_and_entry
    
    if @order.update_attributes(:status => "For-Delivery", :confirmed => Time.now, :seller_confirmation => true)
      @order.update_associated_status("For-Delivery")
      flash[:notice] = ("You buyer is <strong>#{@entry.user.profile.company.name}</strong>.<br> Please deliver ASAP. Thanks!").html_safe
    else
      flash[:error] = "Something went wrong with your request ... please try again later."
    end
    redirect_to :back
  end

  def seller_status # For seller to update status of Orders
    find_order_and_entry

    if params[:seller_status] == "Confirm Payment"
      status = "Paid"
      tag_as_paid
    else
      status = params[:seller_status]
      if @order.update_attribute(:status, status)
        if status == "Delivered"
          @order.update_attributes(:delivered => Date.today, :pay_until => Date.today + @entry.term.name.days)
          flash[:notice] = ("Successfully updated the status of the order to <strong>Delivered</strong>.<br>
          Please send your invoice to buyer asap so we can help you <strong>track the payment</strong>.").html_safe
        elsif status == "Paid"
          tag_as_paid
        end
      end
    end
    @order.update_associated_status(status)
    redirect_to :back
  end

  def buyer_paid # Allows buyer to tag PO as 'Paid' if seller hasn't done so yet
    find_order_and_entry
    status = params[:buyer_status]
    
    if @order.update_attributes(:status => status, :paid_temp => Date.today)
      flash[:notice] = ("Successfully updated the status of the order to <strong>Paid</strong>.<br>
      We will notify the seller to confirm your payment.").html_safe
      OrderMailer.delay.order_paid_alert(@order, @entry)
    else
      flash[:error] = "Something went wrong with your request ... please try again later."
    end
    redirect_to :back
  end

  def cancel
    if params[:bid_ids]
      find_order_and_entry
      @bids = Bid.find(params[:bid_ids])
      @message = current_user.messages.build
      @msg_type = current_user.roles.first.name
    else
      flash[:warning] = "Please select an order item you want to cancel."
      redirect_to :back
    end
  end
  
  def confirm_cancel
    if params[:order][:message][:message].present?
      find_order_and_entry
      @bids = Bid.find(params[:bid_ids])
      @bids.each do |bid|
        bid.cancel_process(params[:msg_type])
      end
      @message = Message.for_cancelled_order(current_user, params[:msg_type], @entry, @order, @bids, params[:order][:message][:message])
      flash[:info] = "Order cancelled. Sayang ..."
      redirect_to @order
      MessageMailer.delay.cancelled_order_message(@order, @message)
    else
      flash[:warning] = "Please indicate your reason for cancelling the order."
      redirect_to :back
    end
  end
  
  def auto_paid
    orders = Order.paid.paid_null
    orders.each do |order|
      order.bids.not_cancelled.each do |bid|
        if bid.paid
          order.update_attribute(:paid, bid.paid)
        elsif order.paid_temp
          order.update_attribute(:paid, order.paid_temp)
        else
          order.update_attribute(:paid, order.pay_until + 1.week)
        end        
        if (bid.fee.present? && bid.fee.reversed?) || bid.fee.nil? 
          Fee.compute(bid, 'Paid', order.id)
        end
      end
      order.bids.not_cancelled.update_all(:status => 'Paid', :paid => order.paid)
      order.line_items.update_all(:status => 'Paid')
    end
    flash[:notice] = "Successfully tagged payments."
    redirect_to :back
  end

  private
    
    def find_order_and_entry
      @order = Order.find(params[:id])
      @entry = @order.entry
    end
    
    def tag_as_paid
      @order.update_attribute(:paid, Date.today)
      flash[:notice] = ("Successfully updated the status of the order to <strong>Paid</strong>.<br>
      Please rate your buyer to close the order.").html_safe
    end

    def initialize_messages
      if current_user.has_role?('admin')
        @priv_messages = @order.messages
      else
        @priv_messages = @order.messages.closed.restricted(current_user.company)
      end
    end
end
