class BuyerController < ApplicationController
  before_filter :check_buyer_role, :except => :fees_print
  respond_to :html, :xml, :js, :xls
  
  def main
    @title = "Buyer's Dashboard"
    @last_activity = current_user.last_sign_in_at
    @ratings = Rating.metered.where(:ratee_id => current_user)
    if current_user.has_role?("powerbuyer")
      @ratings = Rating.metered.where(:ratee_id => current_user.company.users)
      initiate_list
      delivered = Order.where(:company_id => current_user.company).delivered
      due_soon = delivered.due_soon.includes(:bids)
      @due_soon_count = due_soon.count
      @due_soon_amount = due_soon.collect(&:total_order_amounts).sum
      overdue_payments = delivered.overdue.includes(:bids)
      @overdue_payments_count = overdue_payments.count
      @overdue_payments_amount = overdue_payments.collect(&:total_order_amounts).sum
    end
    find_stats
  end
  
  def pending
    @title = 'Pending Entries'
    initiate_list
    @status = ["New", "Edited"]
    find_entries
    @search = @finder.current.desc.search(params[:search])
    @entries = @search.paginate(:page => params[:page], :per_page => 10)
    render 'entries/index'  
  end

  def online
    @title = 'Online Entries'
    initiate_list
    @status = ["Online", "Relisted"]
    find_entries
    @search = @finder.current.desc2.search(params[:search])
    @entries = @search.paginate(:page => params[:page], :per_page => 10)
    render 'entries/index'  
  end

  def results
    @title = 'Bidding Results'
    @tag_collection = ["For-Decision", "Ordered-IP", "Declined-IP"]
    initiate_list # defined in AppController
    find_entries
    @search = @finder.current.asc.search(params[:search])
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
    @orders = @search.inclusions.paginate :page => params[:page], :per_page => 15    
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
      @all_decline_fees = Fee.date_range(params[:start], params[:end], 'i').declined.by_this_buyer(current_user)
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
    @total = entries.metered.count
    @pending = entries.pending.metered.count
    @online = entries.online.current.count
    @decision = entries.results.current.metered.count
    @expired = entries.where(:buyer_status => 'Expired').metered.count
    @expired2 = entries.online.expired.count
    @expired3 = entries.results.expired.metered.count
    @declined = entries.declined.metered.count
    @closed = entries.closed.metered.count
    @orders = orders.count
    @order_items = OrderItem.where(:order_id => orders).collect(&:line_item_id).uniq.count unless OrderItem.nil?
    @with_order_pct = (@order_items.to_f/LineItem.with_bids.where(:entry_id => entries).count.to_f) * 100 unless @order_items.nil? 
    @released = orders.recent.count

    delivered_items =  orders.delivered.includes(:bids)
    @delivered = delivered_items.count
    pay_soon = delivered_items.due_soon
    @pay_soon_count = pay_soon.count
    @pay_soon_amount = pay_soon.collect(&:total_order_amounts).sum
    overdue = delivered_items.overdue
    @overdue_count = overdue.count
    @overdue_amount = overdue.collect(&:total_order_amounts).sum
    due_later = delivered_items - pay_soon - overdue
    @due_later_count = due_later.count
    @due_later_amount = due_later.collect(&:total_order_amounts).sum
    o_paid = orders.paid_and_closed.payment_valid
    @paid_count = o_paid.count
    @paid_amount = o_paid.collect(&:total_order_amounts).sum
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
