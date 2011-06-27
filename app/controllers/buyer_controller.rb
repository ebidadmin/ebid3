class BuyerController < ApplicationController
  before_filter :check_buyer_role, :except => :fees_print
  respond_to :html, :xml, :js, :xls
  
  def main
    @last_activity = current_user.last_sign_in_at
    if current_user.has_role?("powerbuyer")
      @ratings = Rating.metered.where(:ratee_id => current_user.company.users)
      initiate_list
      delivered = Order.where(:company_id => current_user.company).delivered
      due_soon = delivered.due_soon
    else
      @ratings = Rating.metered.where(:ratee_id => current_user)
      delivered = current_user.orders.delivered
      due_soon = delivered.due_soon
    end
    @due_soon_count = due_soon.count
    @due_soon_amount = due_soon.collect(&:order_total).sum
    overdue_payments = delivered.overdue
    @overdue_payments_count = overdue_payments.count
    @overdue_payments_amount = overdue_payments.collect(&:order_total).sum
    @overdue_days = overdue_payments.first.days_overdue unless overdue_payments.blank?
    find_stats
  end
  
  def pending
    @title = 'Pending Entries'
    initiate_list
    @status = ["New", "Edited"]
    find_entries
    @search = @finder.unexpired.desc.search(params[:search])
    @entries = @search.paginate(:page => params[:page], :per_page => 10)
    render 'entries/index'  
  end

  def online
    @title = 'Online Entries'
    initiate_list
    @status = ["Online", "Relisted"]
    find_entries
    @search = @finder.active.desc2.search(params[:search])
    @entries = @search.paginate(:page => params[:page], :per_page => 10)
    render 'entries/index'  
  end

  def results
    @title = 'Bidding Results'
    @tag_collection = ["For-Decision", "Ordered-IP", "Declined-IP"]
    initiate_list # defined in AppController
    find_entries
    @search = @finder.unexpired.asc.search(params[:search])
    @entries = @search.paginate(:page => params[:page], :per_page => 10)
    render 'entries/index'  
  end
  
  def orders
    @title = 'Purchase Orders'
    @sort_order =" PO date - descending order"
    @tag_collection = ["PO Released", "For Delivery", "For-Delivery"]
    initiate_list
    find_orders
    if params[:seller].nil?
      @search = @all_orders.desc.search(params[:search])
    else
      @search = @all_orders.where(:seller_id => params[:seller]).desc.search(params[:search]) 
    end
    @orders = @search.inclusions.paginate :page => params[:page], :per_page => 10    
    render 'orders/index'  
  end

  def payments
    @title = 'Delivered Orders - For Payment'
    @sort_order =" due date - ascending order"
    initiate_list
    @status = "Delivered"
    find_orders
    @search = @all_orders.asc.search(params[:search])    
    @search = @all_orders.where(:seller_id => params[:seller]).asc.search(params[:search]) unless params[:seller].nil?
    @orders = @search.inclusions.with_ratings.paginate :page => params[:page], :per_page => 15    
    
    respond_to do |format|
      format.html { render 'orders/index'  }
      format.xls { send_data @orders.to_xls_data, :filename => 'payments.xls' }
    end
  end

  def payments_print
    @title = 'Delivered Orders - For Payment'
    @sort_order =" due date - ascending order"
    initiate_list
    @status = "Delivered"
    find_orders_for_print
    @search = @all_orders.asc.search(params[:search])    
    @search = @all_orders.where(:seller_id => params[:seller]).asc.search(params[:search]) unless params[:seller].nil?
    @orders = @search.inclusions   
    render :layout => 'print'
  end
  
  def paid
    @title = 'Paid Orders - For Rating'
    @sort_order =" date paid - ascending order"
    initiate_list
    @status = ["Paid", "Closed"]
    find_orders
    @search = @all_orders.asc2.search(params[:search])
    @search = @all_orders.where(:seller_id => params[:seller]).asc2.search(params[:search]) unless params[:seller].nil?
    @orders = @search.inclusions.paginate :page => params[:page], :per_page => 10    
    render 'orders/index'  
  end

  def fees
    @title = "Declined Winning Bids"
    initiate_list # defined in AppController
    if params[:user_id] == 'all'
      @search = Fee.declined.date_range(params[:start], params[:end], 'i').where(:buyer_company_id => current_user.company).search(params[:search])
    else
      @search = Fee.declined.date_range(params[:start], params[:end], 'i').where(:buyer_id => User.find_by_username(params[:user_id])).search(params[:search])
    end
    start_date # defined in AppController
    end_date
    @decline_fees = @search.inclusions.paginate :page => params[:page], :per_page => 30
  end

  def fees_print
    if current_user.has_role?('admin') 
      @all_decline_fees = Fee.date_range(params[:start], params[:end], 'i').declined.by_this_buyer(params[:buyer], 'comp')
    elsif current_user.has_role?('seller')
      @all_decline_fees = Fee.date_range(params[:start], params[:end], 'i').by_this_buyer(params[:buyer], 'comp').declined.by_this_seller(current_user)
    else
      if params[:user_id] == 'all'
        @all_decline_fees = Fee.date_range(params[:start], params[:end], 'i').declined.by_this_buyer(current_user.company, 'comp')
      else
        @all_decline_fees = Fee.date_range(params[:start], params[:end], 'i').declined.by_this_buyer(User.find_by_username(params[:user_id]))
      end
    end
    start_date
    end_date
    buyer_company
    @search = @all_decline_fees.search(params[:search])
    @decline_fees = @search.inclusions.with_orders
    render :layout => 'print'
  end

private 
  
  def find_stats
    if params[:user_id] == 'all'
      entries = Entry.where(:user_id => current_user.company.users)
      orders = Order.where(:company_id => current_user.company)
    else
      entries = defined_user.entries
      orders = defined_user.orders
    end
    @tot_all = entries.count
    @tot_m = entries.metered.count
    @tot_f = entries.ftm.count
    @pend_all = entries.pending.count
    @pend_m = entries.pending.metered.count
    @pend_f = entries.pending.ftm.count
    @online_all = entries.online.unexpired.count
    @online_m = entries.online.unexpired.metered.count
    @online_f = entries.online.unexpired.ftm.count
    @fd_all = entries.results.unexpired.count
    @fd_m = entries.results.unexpired.metered.count
    @fd_f = entries.results.unexpired.ftm.count
    @ord_all = entries.ordered.count
      @ord_all_pct = (@ord_all.to_f / @tot_all.to_f) * 100
    @ord_m = entries.ordered.metered.count
      @ord_m_pct = (@ord_m.to_f / @tot_m.to_f) * 100
    @ord_f = entries.ordered.ftm.count
      @ord_f_pct = (@ord_f.to_f / @tot_f.to_f) * 100
    @etc_all = @tot_all - @pend_all - @online_all - @fd_all - @ord_all
    @etc_m = @tot_m - @pend_m - @online_m - @fd_m - @ord_m
    @etc_f = @tot_f - @pend_f - @online_f - @fd_f - @ord_f

    @line_items = LineItem.where(:entry_id => entries)
    @li_all = @line_items.count
    @li_m = @line_items.metered.count
    @li_f = @line_items.ftm.count
    @lib_all = @line_items.with_bids.count
      @lib_all_pct = (@lib_all.to_f / @li_all.to_f) * 100
    @lib_m = @line_items.with_bids.metered.count
      @lib_m_pct = (@lib_m.to_f / @li_m.to_f) * 100
    @lib_f = @line_items.with_bids.ftm.count
      @lib_f_pct = (@lib_f.to_f / @li_f.to_f) * 100
      
    @oi_all = OrderItem.where(:order_id => orders).collect(&:line_item_id).count
      @oi_all_pct = (@oi_all.to_f / @lib_all.to_f) * 100
    @oi_m = OrderItem.where(:order_id => orders).metered.collect(&:line_item_id).count
      @oi_m_pct = (@oi_m.to_f / @lib_m.to_f) * 100
    @oi_f = OrderItem.where(:order_id => orders).ftm.collect(&:line_item_id).count
      @oi_f_pct = (@oi_f.to_f / @lib_f.to_f) * 100
    @total_delivered = orders.total_delivered
      @td_all = @total_delivered.collect(&:order_total).sum
      @td_m = @total_delivered.metered.collect(&:order_total).sum
      @td_f = @total_delivered.ftm.collect(&:order_total).sum
    @within_term = orders.within_term
      @wt_all = @within_term.collect(&:order_total).sum
      @wt_all_pct = (@wt_all.to_f / @td_all.to_f) * 100 
      @wt_m = @within_term.metered.collect(&:order_total).sum
      @wt_m_pct = (@wt_m.to_f / @td_m.to_f) * 100 
      @wt_f = @within_term.ftm.collect(&:order_total).sum
      @wt_f_pct = (@wt_f.to_f / @td_f.to_f) * 100 
    @overdue = orders.overdue
      @ovr_all = @overdue.collect(&:order_total).sum
      @ovr_all_pct = (@ovr_all.to_f / @td_all.to_f) * 100 
      @ovr_m = @overdue.metered.collect(&:order_total).sum
      @ovr_m_pct = (@ovr_m.to_f / @td_m.to_f) * 100 
      @ovr_f = @overdue.ftm.collect(&:order_total).sum
      @ovr_f_pct = (@ovr_f.to_f / @td_f.to_f) * 100 
    @paid_pending = orders.paid.payment_pending
      @pend_all = @paid_pending.collect(&:order_total).sum
      @pend_all_pct = (@pend_all.to_f / @td_all.to_f) * 100 
      @pend_m = @paid_pending.metered.collect(&:order_total).sum
      @pend_m_pct = (@pend_m.to_f / @td_m.to_f) * 100 
      @pend_f = @paid_pending.ftm.collect(&:order_total).sum
      @pend_f_pct = (@pend_f.to_f / @td_f.to_f) * 100 
    @paid = orders.paid.payment_valid
      @paid_all = @paid.collect(&:order_total).sum
      @paid_all_pct = (@paid_all.to_f / @td_all.to_f) * 100 
      @paid_m = @paid.metered.collect(&:order_total).sum
      @paid_m_pct = (@paid_m.to_f / @td_m.to_f) * 100 
      @paid_f = @paid.ftm.collect(&:order_total).sum
      @paid_f_pct = (@paid_f.to_f / @td_f.to_f) * 100 
    @closed = orders.closed
      @closed_all = @closed.collect(&:order_total).sum
      @closed_all_pct = (@closed_all.to_f / @td_all.to_f) * 100 
      @closed_m = @closed.metered.collect(&:order_total).sum
      @closed_m_pct = (@closed_m.to_f / @td_m.to_f) * 100 
      @closed_f = @closed.ftm.collect(&:order_total).sum
      @closed_f_pct = (@closed_f.to_f / @td_f.to_f) * 100 
    
    @fastest_bid = Bid.where(:entry_id => current_user.company.entries.with_bids.ftm).order(:bid_speed)
  end
  
  def find_orders_for_print
    if params[:user_id] == 'all'
      @all_orders = Order.where(:company_id => current_user.company, :status => @status)
    else
      @all_orders = defined_user.orders.where(:status => @status)
    end
    @sellers = User.where(:id => @all_orders.collect(&:seller_id).uniq).includes(:company).collect { |seller| [seller.company_name, request_path(:seller => seller.id)]}
    @sellers.push(['All', request_path(:seller => nil)]) unless @sellers.blank?
    @sellers_path = request_path(:seller => params[:seller])
  end
  
end
