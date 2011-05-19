class OrdersController < ApplicationController
  def index
  end

  def create
    # raise params.to_yaml
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
    @order_items = @order.order_items
    @order_items1 = @order.bids
  end

  def print
    find_order_and_entry
    @order_items = @order.order_items
    @order_items1 = @order.bids
    # @line_items = @entry.line_items
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
