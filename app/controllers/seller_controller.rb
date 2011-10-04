class SellerController < ApplicationController
  include ActionView::Helpers::TextHelper
  before_filter :check_seller_role
  
  def main
    @last_activity = current_user.last_sign_in_at unless current_user.last_sign_in_at.nil?
    @ratings = Rating.since_eval(eval_date).where(:ratee_id => current_user.company.users)
    @last_bid = current_user.bids.last.created_at unless current_user.bids.last.nil?
    @line_items ||= LineItem.scoped
      @li_all = @line_items.count
      @li_m = @line_items.since_eval(eval_date).count
      @li_f = @line_items.ftm.count
    @own_bids ||= current_user.bids.order(:bid_speed) #ascend_by_bid_speed
      @ob_all = @own_bids.collect(&:line_item_id).uniq.count
      @ob_all_pct = (@ob_all.to_f / @li_all.to_f) * 100
      @ob_m = @own_bids.since_eval(eval_date).collect(&:line_item_id).uniq.count
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
      @tb_m = @own_bids.since_eval(eval_date).count
      @tb_f = @own_bids.ftm.count
    @orig = @own_bids.where(:bid_type => 'original')
      @orig_all = @orig.count
      @orig_m = @orig.since_eval(eval_date).count
      @orig_f = @orig.ftm.count
    @rep = @own_bids.where(:bid_type => 'replacement')
      @rep_all = @rep.count
      @rep_m = @rep.since_eval(eval_date).count
      @rep_f = @rep.ftm.count
    @surp = @own_bids.where(:bid_type => 'surplus')
      @surp_all = @surp.count
      @surp_m = @surp.since_eval(eval_date).count
      @surp_f = @surp.ftm.count
    # @ordered = OrderItem.order_seller_id_eq(current_user)
    # @ordered = Order.where(:seller_id => current_user)
    # @ordered = @own_bids.where(:status => ['For-Delivery', 'Delivered', 'Paid', 'Closed'])
    @ordered = @own_bids.with_order
      @ordered_all = @ordered.count
      @ordered_all_pct = (@ordered_all.to_f / @ob_all.to_f) * 100
      @ordered_m = @ordered.since_eval(eval_date).count
      @ordered_m_pct = (@ordered_m.to_f / @ob_m.to_f) * 100
      @ordered_f = @ordered.ordered_this_month.count
      @ordered_f_pct = (@ordered_f.to_f / @ob_f.to_f) * 100
    @cancelled = @own_bids.cancelled
      @canc_all = @cancelled.count
      @canc_m = @cancelled.since_eval(eval_date).count
      @canc_f = @cancelled.ordered_this_month.count
    @pending = @own_bids.where(:status => 'For-Decision')
      @fdec_all = @pending.count
      @fdec_m = @pending.since_eval(eval_date).count
      @fdec_f = @pending.ftm.count
    @declined = @own_bids.declined
      @decl_all = @declined.count
      @decl_m = @declined.since_eval(eval_date).count
      @decl_f = @declined.ftm.count
    @lose = @own_bids.where(:status => ['Lose', 'Dropped', 'Expired'])
      @lose_all = @lose.count
      @lose_m = @lose.since_eval(eval_date).count
      @lose_f = @lose.ftm.count
    @new = @own_bids.where(:status => ['Submitted', 'Updated'])
      @nb_all = @new.count
      @nb_m = @new.since_eval(eval_date).count
      @nb_f = @new.ftm.count
    @days_m = (Time.now.to_date - eval_date).to_f
    @average_m = (@tb_m/@days_m).round(2)
    unless Date.today  == Time.now.beginning_of_month.to_date  # this condition prevents zero divisor
      @days_f = (Time.now.to_date - Time.now.beginning_of_month.to_date).to_f
      @average_f = (@tb_f/@days_f).round(2)
    else
      @days_f = 1
      @average_f = @tb_f.round(2)
    end
    
    @ebid_orders ||= Order.scoped
      @eb_all = @ebid_orders.sum(:order_total)
      @eb_m = @ebid_orders.since_eval(eval_date).sum(:order_total)
      @eb_f = @ebid_orders.ftm.sum(:order_total)
      
    @own_orders = @ordered
      @own_all = @own_orders.sum(:total)
      @own_all_pct = (@own_all.to_f / @eb_all.to_f) * 100
      @own_m = @own_orders.since_eval(eval_date).sum(:total)
      @own_m_pct = (@own_m.to_f / @eb_m.to_f) * 100
      @own_f = @own_orders.ftm.sum(:total)
      @own_f_pct = (@own_f.to_f / @eb_f.to_f) * 100
    @new_orders = @own_orders.order_recent
      @new_all = @new_orders.sum(:total)
      @new_m = @new_orders.metered.sum(:total)
      @new_f = @new_orders.ftm.sum(:total)
    @cancelled_orders = @cancelled
      @co_all = @cancelled_orders.sum(:total)
      @co_m = @cancelled_orders.metered.sum(:total)
      @co_f = @cancelled_orders.ftm.sum(:total)
    @total_delivered = @own_orders.delivered_not_null.not_cancelled
      @td_all = @total_delivered.sum(:total)
      @td_m = @total_delivered.metered.sum(:total)
      @td_f = @total_delivered.ftm.sum(:total)
    @within_term = @total_delivered.order_within_term
      @wt_all = @within_term.sum(:total)
      @wt_all_pct = (@wt_all.to_f / @td_all.to_f) * 100 
      @wt_m = @within_term.metered.sum(:total)
      @wt_m_pct = (@wt_m.to_f / @td_m.to_f) * 100 
      @wt_f = @within_term.ftm.sum(:total)
      @wt_f_pct = (@wt_f.to_f / @td_f.to_f) * 100 
    @overdue = @total_delivered.order_overdue
      @ovr_all = @overdue.sum(:total)
      @ovr_all_pct = (@ovr_all.to_f / @td_all.to_f) * 100 
      @ovr_m = @overdue.metered.sum(:total)
      @ovr_m_pct = (@ovr_m.to_f / @td_m.to_f) * 100 
      @ovr_f = @overdue.ftm.sum(:total)
      @ovr_f_pct = (@ovr_f.to_f / @td_f.to_f) * 100 
    @paid_pending = @total_delivered.order_needs_confirmation
      @pend_all = @paid_pending.sum(:total)
      @pend_all_pct = (@pend_all.to_f / @td_all.to_f) * 100 
      @pend_m = @paid_pending.metered.sum(:total)
      @pend_m_pct = (@pend_m.to_f / @td_m.to_f) * 100 
      @pend_f = @paid_pending.ftm.sum(:total)
      @pend_f_pct = (@pend_f.to_f / @td_f.to_f) * 100 
    @paid = @total_delivered.order_needs_rating
      @paid_all = @paid.sum(:total)
      @paid_all_pct = (@paid_all.to_f / @td_all.to_f) * 100 
      @paid_m = @paid.metered.sum(:total)
      @paid_m_pct = (@paid_m.to_f / @td_m.to_f) * 100 
      @paid_f = @paid.ftm.sum(:total)
      @paid_f_pct = (@paid_f.to_f / @td_f.to_f) * 100 
    @closed = @total_delivered.status_like('closed')
      @closed_all = @closed.sum(:total)
      @closed_all_pct = (@closed_all.to_f / @td_all.to_f) * 100 
      @closed_m = @closed.metered.sum(:total)
      @closed_m_pct = (@closed_m.to_f / @td_m.to_f) * 100 
      @closed_f = @closed.ftm.sum(:total)
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
    @all_orders = Order.by_this_seller(current_user.company.users).recent.order(:confirmed)
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
    @search = Entry.for_seller_archives.where('entries.created_at >= ?', eval_date).user_company_friendships_friend_id_eq(current_user.company).search(params[:search])
    @entries = @search.desc.includes(:car_brand, :car_model, :car_variant, :city, :term, :photos, :messages).paginate(:page => params[:page], :per_page => 10)
    @company = current_user.company
  end
  
end
