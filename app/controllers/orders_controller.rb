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
        bid.update_attributes(:status => "Ordered", :ordered => Date.today, :order_id => OrderItem.line_item_id_eq(@line_item).last.order.id, :declined => nil, :expired => nil)
        bid.update_unselected_bids(@line_item)
        @line_item.update_attribute(:status, "Ordered")
      end
      @entry.update_status
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

  def confirm # For seller to confirm PO
    find_order_and_entry
    
    if @order.update_attributes(:status => "For Delivery", :seller_confirmation => true)
      @order.update_associated_status("For Delivery")
      flash[:notice] = ("You buyer is <strong>#{@entry.user.profile.company.name}</strong>.<br> Please deliver ASAP. Thanks!").html_safe
      redirect_to :back
    end
  end

  def seller_status # For seller to update status of Orders
    # raise params.to_yaml
    find_order_and_entry
    status = params[:status]

    if @order.update_attribute(:status, status)
      if status == "Delivered"
        @order.update_attributes(:delivered => Date.today, :pay_until => Date.today + @entry.term.name.days)
        flash[:notice] = ("Successfully updated the status of the order to <strong>Delivered</strong>.<br>
        Please send your invoice to buyer asap so we can help you <strong>track the payment</strong>.").html_safe
      elsif status == "Paid"
        @order.update_attribute(:paid, Date.today)
        flash[:notice] = ("Successfully updated the status of the order to <strong>Paid</strong>.<br>
        Please rate your buyer to close the order.").html_safe
      end
      @order.update_associated_status(status)
      redirect_to seller_orders_path(current_user) #:back
    end
  end

  private
    
    def find_order_and_entry
      @order = Order.find(params[:id])
      @entry = @order.entry
    end
end
