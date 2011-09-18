class SellerController < ApplicationController
  include ActionView::Helpers::TextHelper
  before_filter :check_seller_role
  
  def main
    @last_activity = current_user.last_sign_in_at unless current_user.last_sign_in_at.nil?
    @ratings = Rating.metered.where(:ratee_id => current_user.company.users)
    @last_bid = current_user.bids.last.created_at unless current_user.bids.last.nil?
    @line_items = LineItem.scoped
      @li_all = @line_items.count
      @li_m = @line_items.metered.count
      @li_f = @line_items.ftm.count
    @own_bids = current_user.bids.order(:bid_speed) #ascend_by_bid_speed
      @ob_all = @own_bids.collect(&:line_item_id).uniq.count
      @ob_all_pct = (@ob_all.to_f / @li_all.to_f) * 100
      @ob_m = @own_bids.metered.collect(&:line_item_id).uniq.count
      @ob_m_pct = (@ob_m.to_f / @li_m.to_f) * 100
      @ob_f = @own_bids.ftm.collect(&:line_item_id).uniq.count
      @ob_f_pct = (@ob_f.to_f / @li_f.to_f) * 100
    @missed = @li_all -  @ob_all
      @msd_all_pct = (@missed.to_f / @li_all.to_f) * 100
      @msd_m = @li_m - @ob_m
      @msd_m_pct = (@msd_m.to_f / @li_m.to_f) * 100
      @msd_f = @li_f - @ob_f
      @msd_f_pct = (@msd_f.to_f / @li_f.to_f) * 100
    @total_bids =  @own_bids.count
      @tb_m = @own_bids.metered.count
      @tb_f = @own_bids.ftm.count
    @orig = @own_bids.where(:bid_type => 'original')
      @orig_all = @orig.count
      @orig_m = @orig.metered.count
      @orig_f = @orig.ftm.count
    @rep = @own_bids.where(:bid_type => 'replacement')
      @rep_all = @rep.count
      @rep_m = @rep.metered.count
      @rep_f = @rep.ftm.count
    @surp = @own_bids.where(:bid_type => 'surplus')
      @surp_all = @surp.count
      @surp_m = @surp.metered.count
      @surp_f = @surp.ftm.count
    @ordered = OrderItem.order_seller_id_eq(current_user)
    # @ordered = Order.where(:seller_id => current_user)
    # @ordered = @own_bids.where(:status => ['Ordered', 'For-Delivery', 'Delivered', 'Closed'])
    # @ordered = @own_bids.where('bids.order_id IS NOT NULL')
      @ordered_all = @ordered.count
      @ordered_all_pct = (@ordered_all.to_f / @ob_all.to_f) * 100
      @ordered_m = @ordered.metered.count
      @ordered_m_pct = (@ordered_m.to_f / @ob_m.to_f) * 100
      @ordered_f = @ordered.ftm.count
      @ordered_f_pct = (@ordered_f.to_f / @ob_f.to_f) * 100
    @cancelled = @ordered.where("status LIKE ?", "%Cancelled%")
      @canc_all = @cancelled.count
      @canc_m = @cancelled.metered.count
      @canc_f = @cancelled.ftm.count
    @pending = @own_bids.where(:status => 'For-Decision')
      @fdec_all = @pending.count
      @fdec_m = @pending.metered.count
      @fdec_f = @pending.ftm.count
    @declined = @own_bids.where(:status => 'Declined')
      @decl_all = @declined.count
      @decl_m = @declined.metered.count
      @decl_f = @declined.ftm.count
    @lose = @own_bids.where(:status => ['Lose', 'Dropped', 'Expired'])
      @lose_all = @lose.count
      @lose_m = @lose.metered.count
      @lose_f = @lose.ftm.count
    @new = @own_bids.where(:status => ['Submitted', 'Updated'])
      @nb_all = @new.count
      @nb_m = @new.metered.count
      @nb_f = @new.ftm.count
    @days_m = (Time.now.to_date - '2011-04-16'.to_date).to_f
    @average_m = (@tb_m/@days_m).round(2)
    unless Date.today  == Time.now.beginning_of_month.to_date  # this condition prevents zero divisor
      @days_f = (Time.now.to_date - Time.now.beginning_of_month.to_date).to_f
      @average_f = (@tb_f/@days_f).round(2)
    else
      @days_f = 1
      @average_f = @tb_f.round(2)
    end
    
    @ebid_orders = Order.scoped
      @eb_all = @ebid_orders.collect(&:order_total).sum
      @eb_m = @ebid_orders.metered.collect(&:order_total).sum
      @eb_f = @ebid_orders.ftm.collect(&:order_total).sum
    @own_orders = @ebid_orders.where(:seller_id => current_user)
      @own_all = @own_orders.collect(&:order_total).sum
      @own_all_pct = (@own_all.to_f / @eb_all.to_f) * 100
      @own_m = @own_orders.metered.collect(&:order_total).sum
      @own_m_pct = (@own_m.to_f / @eb_m.to_f) * 100
      @own_f = @own_orders.ftm.collect(&:order_total).sum
      @own_f_pct = (@own_f.to_f / @eb_f.to_f) * 100
    @new_orders = @own_orders.recent
      @new_all = @new_orders.collect(&:order_total).sum
      @new_m = @new_orders.metered.collect(&:order_total).sum
      @new_f = @new_orders.ftm.collect(&:order_total).sum
    @cancelled_orders = @own_orders.where("status LIKE ?", "%Cancelled%")
      @co_all = @cancelled_orders.collect(&:order_total).sum
      @co_m = @cancelled_orders.metered.collect(&:order_total).sum
      @co_f = @cancelled_orders.ftm.collect(&:order_total).sum
    @total_delivered = @own_orders.total_delivered
      @td_all = @total_delivered.collect(&:order_total).sum
      @td_m = @total_delivered.metered.collect(&:order_total).sum
      @td_f = @total_delivered.ftm.collect(&:order_total).sum
    @within_term = @own_orders.within_term
      @wt_all = @within_term.collect(&:order_total).sum
      @wt_all_pct = (@wt_all.to_f / @td_all.to_f) * 100 
      @wt_m = @within_term.metered.collect(&:order_total).sum
      @wt_m_pct = (@wt_m.to_f / @td_m.to_f) * 100 
      @wt_f = @within_term.ftm.collect(&:order_total).sum
      @wt_f_pct = (@wt_f.to_f / @td_f.to_f) * 100 
    @overdue = @own_orders.overdue
      @ovr_all = @overdue.collect(&:order_total).sum
      @ovr_all_pct = (@ovr_all.to_f / @td_all.to_f) * 100 
      @ovr_m = @overdue.metered.collect(&:order_total).sum
      @ovr_m_pct = (@ovr_m.to_f / @td_m.to_f) * 100 
      @ovr_f = @overdue.ftm.collect(&:order_total).sum
      @ovr_f_pct = (@ovr_f.to_f / @td_f.to_f) * 100 
    @paid_pending = @own_orders.paid.payment_pending
      @pend_all = @paid_pending.collect(&:order_total).sum
      @pend_all_pct = (@pend_all.to_f / @td_all.to_f) * 100 
      @pend_m = @paid_pending.metered.collect(&:order_total).sum
      @pend_m_pct = (@pend_m.to_f / @td_m.to_f) * 100 
      @pend_f = @paid_pending.ftm.collect(&:order_total).sum
      @pend_f_pct = (@pend_f.to_f / @td_f.to_f) * 100 
    @paid = @own_orders.paid.payment_valid
      @paid_all = @paid.collect(&:order_total).sum
      @paid_all_pct = (@paid_all.to_f / @td_all.to_f) * 100 
      @paid_m = @paid.metered.collect(&:order_total).sum
      @paid_m_pct = (@paid_m.to_f / @td_m.to_f) * 100 
      @paid_f = @paid.ftm.collect(&:order_total).sum
      @paid_f_pct = (@paid_f.to_f / @td_f.to_f) * 100 
    @closed = @own_orders.closed
      @closed_all = @closed.collect(&:order_total).sum
      @closed_all_pct = (@closed_all.to_f / @td_all.to_f) * 100 
      @closed_m = @closed.metered.collect(&:order_total).sum
      @closed_m_pct = (@closed_m.to_f / @td_m.to_f) * 100 
      @closed_f = @closed.ftm.collect(&:order_total).sum
      @closed_f_pct = (@closed_f.to_f / @td_f.to_f) * 100 
  end
  
  def hub
    all_entries = Entry.online.active
    @friend_entries = all_entries.user_company_friendships_friend_id_eq(current_user.company)
    @brand_links = @friend_entries.collect(&:car_brand).uniq.collect { |brand| [brand.name, seller_hub_path(current_user, :brand => brand.name)] }  #.sort! { |a,b| a.name.downcase <=> b.name.downcase }
    @brand_links.push(['All', seller_hub_path(current_user, :brand => 'all')])
    @current_path =  seller_hub_path(current_user, :brand => params[:brand])
    @company = current_user.company
    
    if params[:brand] == 'all'
      @entries = @friend_entries.seller_inclusions.paginate(:page => params[:page], :per_page => 10)
    else
      brand = CarBrand.find_by_name(params[:brand])
      @entries = @friend_entries.seller_inclusions.where(:car_brand_id => brand).paginate :page => params[:page], :per_page => 10
    end
  end
  
  def show
    @back = request.referrer
    @entry = Entry.find(params[:id])
    @priv_messages = @entry.messages.closed.restricted(current_user.company)
    @pub_messages = @entry.messages.open
    if @entry.is_now_online?
      @line_items = @entry.line_items.order('status DESC').includes(:car_part, :bids)
    else
      @line_items = @entry.line_items.includes(:car_part, :bids)
    end
    @company = current_user.company
    unless @entry.user.company.friends.include?(@company) || current_user.has_role?('admin')
      flash[:error] = "Sorry, <strong>#{@company.name}</strong>.  Your access for this entry is not allowed.  Call 892-5835 to fix this.".html_safe
      redirect_to :back
    end 
  end
  
  def monitor
    bids = Bid.where(:user_id => current_user.company.users).desc
    @brand_links = CarBrand.find(bids.collect(&:car_brand_id).uniq).collect { |brand| [brand.name, seller_monitor_path(current_user, :brand => brand.name)] }
    @brand_links.push(['All', seller_monitor_path(current_user, :brand => nil)])
    if params[:brand] == 'all'
      @search = bids.search(params[:search])
    elsif params[:brand]
      brand = CarBrand.find_by_name(params[:brand])
      @search = bids.where(:car_brand_id => brand).search(params[:search])
    else
      @search = bids.search(params[:search])
    end
    @bids = @search.inclusions.paginate :page => params[:page], :per_page => 20    
    @current_path =  seller_monitor_path(current_user, :brand => params[:brand])
    # render 'bids/index' 
  end

  def orders
    @title = "Purchase Orders"
    @sort_order =" PO date - descending order"
    @all_orders = Order.by_this_seller(current_user.company.users).recent.order('confirmed')
    @search = @all_orders.search(params[:search])
    if params[:status]
      @orders = Order.by_this_seller(current_user.company.users).where(:status => params[:status]).desc.inclusions_for_seller.paginate :page => params[:page], :per_page => 10
    else
      @orders = @search.inclusions_for_seller.paginate :page => params[:page], :per_page => 10    
    end
    render 'orders/index'  
  end

  def payments
    @title = "Delivered Orders - For Payment"
    @sort_order =" due date (per vehicle) - ascending order"
    @all_orders = Order.by_this_seller(current_user.company.users).delivered.unpaid.asc
    @search = @all_orders.search(params[:search])
    @orders = @search.inclusions_for_seller.paginate :page => params[:page], :per_page => 10    
    render 'orders/index'  
  end

  def feedback
    @title = "Paid Orders - Rate Your Buyers"
    @sort_order =" date paid (per vehicle) - ascending order"
    @all_orders = Order.by_this_seller(current_user.company.users).paid
    @search = @all_orders.search(params[:search])
    @orders = @search.inclusions_for_seller.with_ratings.paginate :page => params[:page], :per_page => 10    
    render 'orders/index'  
  end
  
  def closed
    @title = "Paid and Closed Orders"
    @sort_order =" date paid (per vehicle) - ascending order"
    @all_orders = Order.by_this_seller(current_user.company.users).closed.order('paid DESC')
    @search = @all_orders.search(params[:search])
    @orders = @search.paginate :page => params[:page], :per_page => 10    
    render 'orders/index'  
  end
  
  def fees
    @title = "Market Fees for Paid Orders"
    # @sort_order =" date PO was paid - descending order"
    @all_market_fees = Fee.date_range(params[:start], params[:end]).ordered.by_this_seller(current_user.company.users)
    start_date
    end_date
    @search = @all_market_fees.search(params[:search])
    @market_fees = @search.inclusions.with_orders.paginate :page => params[:page], :per_page => 30
    @period_path = seller_fees_path(current_user)
  end
  
  def fees_print
    if current_user.has_role?('admin')
      @all_market_fees = Fee.date_range(params[:start], params[:end]).ordered.by_this_seller(params[:seller], 'comp')
    else
      @all_market_fees = Fee.date_range(params[:start], params[:end]).ordered.by_this_seller(current_user.company.users)
    end
    start_date
    end_date
    seller_company
    @search = @all_market_fees.search(params[:search])
    @market_fees = @search.inclusions.with_orders
    render :layout => 'print'
  end
  
  def declines
    @title = "Decline Fees"
    @all_decline_fees = Fee.date_range(params[:start], params[:end], 'i').declined.by_this_seller(current_user.company.users)
    start_date
    end_date

    @search = @all_decline_fees.by_this_buyer(params[:buyer], 'comp').search(params[:search])
    @decline_fees = @search.inclusions.paginate :page => params[:page], :per_page => 30

    @buyers = @all_decline_fees.collect(&:buyer_company_id).uniq.collect { |buyer| [truncate(Company.find(buyer).name, :length => 20), seller_declines_path(:buyer => buyer)] }
    @buyers.push(['All', seller_declines_path(:buyer => nil)]) unless @buyers.blank?
    @buyers_path = seller_declines_path(:buyer => params[:buyer])
    @period_path = seller_declines_path(current_user)
  end
 
  def archives
    @search = Entry.for_seller_archives.where('entries.created_at >= ?', metering_date).user_company_friendships_friend_id_eq(current_user.company).search(params[:search])
    @entries = @search.desc.includes(:car_brand, :car_model, :car_variant, :city, :term, :photos, :messages).paginate(:page => params[:page], :per_page => 10)
    @company = current_user.company
  end
  
  private
  
  def metering_date
    current_user.company.metering_date
  end
end
