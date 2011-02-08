class SellerController < ApplicationController
  before_filter :check_seller_role
  
  def main
    @last_activity = current_user.last_sign_in_at unless current_user.last_sign_in_at.nil?
    @ratings = Rating.where(:ratee_id => current_user)
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
    @paid_pending = orders.paid.payment_pending.collect(&:total_order_amounts).sum
    @paid_pending_percent = (@paid_pending.to_f / @total_delivered.to_f) * 100 unless @total_delivered.nil?
    @paid = orders.paid.payment_valid.collect(&:total_order_amounts).sum
    @paid_percent = (@paid.to_f / @total_delivered.to_f) * 100 unless @total_delivered.nil?
    @closed = orders.closed.collect(&:total_order_amounts).sum
    @closed_percent = (@closed.to_f / @total_delivered.to_f) * 100 unless @total_delivered.nil?
  end
  
  def hub
    entries = Entry.online.current.desc2.includes(:car_brand, :car_model, :car_variant, :city, :term, :line_items)
    @brand_links = entries.collect(&:car_brand).uniq 
    if params[:brand] == 'all'
      @entries = entries.paginate(:page => params[:page], :per_page => 10)
    else
      brand = CarBrand.find_by_name(params[:brand])
      @entries = entries.where(:car_brand_id => brand).paginate :page => params[:page], :per_page => 10
    end
  end
  
  def show
    @entry = Entry.find(params[:id])
    if @entry.buyer_status == 'Relisted'
      @line_items = @entry.line_items.online.includes(:car_part, :bids)
    else
      @line_items = @entry.line_items.includes(:car_part, :bids)
    end
    company = current_user.company
    unless current_user.has_role?('admin') || @entry.user.company.friendships.collect(&:friend_id).include?(company.id)
      flash[:error] = "Sorry, <strong>#{company.name}</strong>.  Your access for this item is not allowed.  Call 892-5835 to fix this.".html_safe
      redirect_to :back
    end 
  end
  
  def monitor
    @search = current_user.bids.desc.search(params[:search])
    @bids = @search.inclusions.paginate :page => params[:page], :per_page => 20    
    render 'bids/index' 
  end

  def orders
    @title = "Purchase Orders"
    @sort_order =" PO date - descending order"
    @all_orders = Order.by_this_seller(current_user).recent
    @search = @all_orders.search(params[:search])
    if params[:status]
      @orders = Order.by_this_seller(current_user).where(:status => params[:status]).desc.inclusions_for_seller.paginate :page => params[:page], :per_page => 10
    else
      @orders = @search.inclusions_for_seller.paginate :page => params[:page], :per_page => 10    
    end
    render 'orders/index'  
  end

  def payments
    @title = "Delivered Orders - For Payment"
    @sort_order =" due date (per vehicle) - ascending order"
    @all_orders = Order.by_this_seller(current_user).delivered.unpaid.asc
    @search = @all_orders.search(params[:search])
    @orders = @search.inclusions_for_seller.paginate :page => params[:page], :per_page => 10    
    render 'orders/index'  
  end

  def feedback
    @title = "Paid Orders - Rate Your Buyers"
    @sort_order =" date paid (per vehicle) - ascending order"
    @all_orders = Order.by_this_seller(current_user).paid
    @search = @all_orders.search(params[:search])
    @orders = @search.inclusions_for_seller.with_ratings.paginate :page => params[:page], :per_page => 10    
    render 'orders/index'  
  end
  
  def closed
    @title = "Paid and Closed Orders"
    @sort_order =" date paid (per vehicle) - ascending order"
    @all_orders = Order.by_this_seller(current_user).closed.order('paid DESC')
    @search = @all_orders.search(params[:search])
    @orders = @search.paginate :page => params[:page], :per_page => 10    
    render 'orders/index'  
  end
  
  def fees
    @title = "Market Fees for Paid Orders"
    @sort_order =" date PO was paid - descending order"
    @all_market_fees = Fee.ordered.by_this_seller(current_user)
    @search = @all_market_fees.search(params[:search])
    @market_fees = @search.inclusions.with_orders.paginate :page => params[:page], :per_page => 30
  end
  
  def declines
    @title = "Decline Fees"
    @all_decline_fees = Fee.by_this_seller(current_user).declined
    # @total_bids = Bid.count
    # @percentage_declined = (@all_decline_fees.count.to_f/@total_bids.to_f) * 100
    @search = @all_decline_fees.search(params[:search])
    @decline_fees = @search.inclusions.paginate :page => params[:page], :per_page => 30
    @group = @decline_fees.group_by(&:entry)

    # @buyers = @all_decline_fees.collect(&:buyer_company_id).uniq.collect { |buyer| [Company.find(buyer).name, seller_declines_path(:buyer => buyer)] }
    # @buyers.push(['All', seller_declines_path(:buyer => nil)]) unless @buyers.blank?
    # @buyers_path = seller_declines_path(:buyer => params[:buyer])
  end

end
