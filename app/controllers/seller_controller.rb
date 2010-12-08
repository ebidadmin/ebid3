class SellerController < ApplicationController
  before_filter :check_seller_role
  
  def main
    @last_activity = current_user.last_sign_in_at unless current_user.last_sign_in_at.nil?
    @last_bid = current_user.bids.last.created_at unless current_user.bids.last.nil?
    @line_items_count = LineItem.all.size
    @bids_count = current_user.bids.collect(&:line_item_id).uniq.count
    @bid_percentage = (@bids_count.to_f / @line_items_count.to_f) * 100
    @missed_count = @line_items_count - @bids_count
    @missed_percentage = 100 - @bid_percentage
    
    orders = Order.by_this_seller(current_user)
    @new_orders = orders.recent.collect(&:total_order_amounts).sum
    @total_delivered = orders.total_delivered.collect(&:total_order_amounts).sum
    @within_term = orders.within_term.collect(&:total_order_amounts).sum
    @within_term_percent = (@within_term.to_f / @total_delivered.to_f) * 100 unless @total_delivered.nil?
    @overdue = orders.overdue.collect(&:total_order_amounts).sum
    @overdue_percent = (@overdue.to_f / @total_delivered.to_f) * 100 unless @total_delivered.nil?
    @paid = orders.paid.collect(&:total_order_amounts).sum
    @paid_percent = (@paid.to_f / @total_delivered.to_f) * 100 unless @total_delivered.nil?
    @closed = orders.closed.collect(&:total_order_amounts).sum
    @closed_percent = (@closed.to_f / @total_delivered.to_f) * 100 unless @total_delivered.nil?
  end
  
  def hub
    entries = Entry.online.current.desc
    @brand_links = entries.collect(&:car_brand).uniq 
    if params[:brand] == 'all'
      @entries = entries.paginate(:page => params[:page], :per_page => 10)
    else
      brand = CarBrand.find_by_name(params[:brand])
      @entries = entries.where(:car_brand_id => brand).paginate :page => params[:page], :per_page => 10
    end
  end
  
  def show
    @entry = Entry.find(params[:id], :joins => [:line_items])
    @line_items = @entry.line_items
    # company = current_user.company
    # unless current_user.has_role?('admin') || @entry.user.company.friendships.collect(&:friend_id).include?(company.id)
    #   flash[:error] = "Sorry, <strong>#{company.name}</strong>.  Your access for this item is not allowed.  Call 892-5835 to fix this."
    #   redirect_to login_path
    # end 
  end
  
  def monitor
    @search = current_user.bids.desc.search(params[:search])
    @bids = @search.paginate :page => params[:page], :per_page => 10    
    render 'bids/index' 
  end

  def orders
    @title = "Purchase Orders"
    @all_orders = Order.by_this_seller(current_user).recent
    @search = @all_orders.search(params[:search])
    @orders = @search.paginate :page => params[:page], :per_page => 10    
    if params[:status]
      @orders = Order.by_this_seller(current_user).where(:status => params[:status]).desc.paginate :page => params[:page], :per_page => 10
    end
    render 'orders/index'  
  end

  def payments
    @title = "Delivered Orders - For Payment"
    @all_orders = Order.by_this_seller(current_user).delivered.unpaid.asc
    @search = @all_orders.search(params[:search])
    @orders = @search.paginate :page => params[:page], :per_page => 10    
    render 'orders/index'  
  end

  def feedback
    @title = "Paid Orders - Rate Your Buyers"
    @all_orders = Order.by_this_seller(current_user).paid
    @search = @all_orders.search(params[:search])
    @orders = @search.paginate :page => params[:page], :per_page => 10    
    render 'orders/index'  
  end
  
  def fees
    @title = "Transaction Fees for Paid Orders"
    @all_orders = Order.by_this_seller(current_user).paid_and_closed
    @orders = @all_orders.paginate :page => params[:page], :per_page => 10
  end

end
