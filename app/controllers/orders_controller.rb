class OrdersController < ApplicationController
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
      @order.initialize_order(current_user, bid_user, @client_ip)
      OrderItem.populate(@order, user_bids)
      @order.order_total = user_bids.collect(&:total).sum
      @orders << @order
    end 

    if @orders.all?(&:valid?) 
      @entry.orders << @orders 
      @bids.each do |bid|
        @line_item = LineItem.find(bid.line_item_id)
        bid.update_attributes(:status => "PO Released", :ordered => Date.today, :order_id => OrderItem.line_item_id_eq(@line_item).last.order.id, :fee => nil, :declined => nil, :expired => nil)
        bid.update_unselected_bids(@line_item)
        @line_item.update_attribute(:status, "PO Released")
      end
      @entry.update_status unless @entry.buyer_status == 'Relisted'
      OrderMailer.delay.order_alert(@orders)
      unless @orders.count < 2
        flash[:notice] = "Your POs have been released and will be processed right away. Thanks!"
        redirect_to @entry 
      else
        flash[:notice] = ("Your PO has been released and will be processed right away.<br> 
          Your supplier is <strong>#{@order.seller.profile.company.name}</strong>. Thanks!").html_safe
        redirect_to @order
      end
    else
      @order.seller_id = nil #This hides seller's name again, since PO is not yet released
      flash[:error] = ("There was a problem releasing your PO.<br> <strong>Is required info complete?</strong>").html_safe
      render 'bids/accept'
    end
  end

  def show
    find_order_and_entry
    # @order_items = @order.order_items
    @order_items1 = @order.bids#.not_cancelled
    @priv_messages = @order.messages.closed.restricted(current_user.company)
  end

  def print
    find_order_and_entry
    @order_items1 = @order.bids.not_cancelled
    render :layout => 'print'
  end

  def confirm # For seller to confirm PO
    find_order_and_entry
    
    if @order.update_attributes(:status => "For-Delivery", :confirmed => Date.today, :seller_confirmation => true)
      @order.update_associated_status("For-Delivery")
      flash[:notice] = ("You buyer is <strong>#{@entry.user.profile.company.name}</strong>.<br> Please deliver ASAP. Thanks!").html_safe
      redirect_to :back
    end
  end

  def seller_status # For seller to update status of Orders
    # raise params.to_yaml
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
      redirect_to :back
      OrderMailer.delay.order_paid_alert(@order, @entry)
    end
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
    # raise params.to_yaml
    if params[:order][:message][:message].present?
      find_order_and_entry
      @bids = Bid.find(params[:bid_ids])
      @bids.each do |bid|
        bid.update_attribute(:status, "Cancelled by #{params[:msg_type]}")
        bid.line_item.update_attribute(:status, "Cancelled by #{params[:msg_type]}")
      end
      @message = current_user.messages.build
      @message.user_company_id = current_user.company.id
      @message.user_type = params[:msg_type]
      @message.entry_id = @entry.id 
      if params[:msg_type] == 'seller'
        @message.receiver_id = @entry.user_id
        @message.receiver_company_id = @entry.company_id
      elsif params[:msg_type] == 'buyer'
        @message.receiver_id = @order.seller_id
        @message.receiver_company_id = @order.seller.company.id
      end
      if @order.bids.cancelled.count == @order.order_items.count
        @message.message = "ENTIRE ORDER cancelled (#{Time.now.strftime('%b %d, %Y %a %R')}): #{@bids.collect { |b| b.line_item.part_name}.to_sentence}."
        @message.message << " REASON: #{params[:order][:message][:message]}"
        @order.messages << @message
        @order.update_attributes(:status => "Cancelled by #{params[:msg_type]}", :order_total => @order.bids.collect(&:total).sum)
        flash[:error] = "Cancelled the ENTIRE ORDER."
      else
        @message.message = "PARTIAL ORDER cancelled (#{Time.now.strftime('%b %d, %Y %a %R')}): #{@bids.collect { |b| b.line_item.part_name}.to_sentence}."
        @message.message << " REASON: #{params[:order][:message][:message]}"
        @order.messages << @message
        @order.update_attribute(:order_total, @order.order_total - @bids.collect(&:total).sum) unless  @order.order_total == 0
        flash[:error] = "Cancelled some order items."
      end
      redirect_to @order
    else
      flash[:warning] = "Please indicate your reason for cancelling the order."
      redirect_to :back
    end
    #TODO award to next bidder?
  end
  
  def auto_paid
    orders = Order.paid.paid_null
    orders.each do |order|
      order.bids.each do |bid|
        if bid.paid
          order.update_attribute(:paid, bid.paid)
        elsif order.paid_temp
          order.update_attribute(:paid, order.paid_temp)
        else
          order.update_attribute(:paid, order.pay_until + 1.week)
        end        
        if bid.fee.nil?
          Fee.compute(bid, 'Paid', order.id)
        end
      end
      order.bids.update_all(:status => 'Paid', :paid => order.paid)
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
end
