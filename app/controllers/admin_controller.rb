class AdminController < ApplicationController
  before_filter :check_admin_role

  def index
    @users = User.active
    get_stats
  end

  def entries
    @title = 'All Entries'
    @user_group = Role.find_by_name('buyer').users.order('username').collect { |user| [user.username_for_menu, admin_entries_path(:user_id => user.username.downcase)] }
    @user_group.push(['All', admin_entries_path(:user_id => 'all')])
    @current_path = admin_entries_path(params[:user_id])
    entries = Entry.scoped

    @tag_collection = entries.collect(&:buyer_status).uniq
    @status_tags = @tag_collection.collect { |tag| [tag, request_path(:status => tag)] } 
    @status_tags.push(['All', request_path(:status => nil)]) 
    @status_path = request_path(:status => params[:status])
    @status = params[:status] unless params[:status].nil?
    @status = @tag_collection if params[:status].nil?
 
    if params[:user_id] == 'all'
      @search = entries.where(:buyer_status => @status).search(params[:search])
    else
      @search = entries.where(:user_id => User.find_by_username(params[:user_id]), :buyer_status => @status).search(params[:search])
    end
    @entries = @search.desc.admin_inclusions.paginate(:page => params[:page], :per_page => 10)
    render 'entries/index'
  end

  def online
    @title = "What's Online?"
    @search = Entry.online.active.admin_inclusions.search(params[:search])
    @entries = @search.paginate(:page => params[:page], :per_page => 10)
    render 'entries/index'  
  end

  def bids
    # @search = LineItem.with_bids.search(params[:search])
    # @line_items = @search.desc.inclusions2.paginate :page => params[:page], :per_page => 20 
    # render 'bids/index' 
  end
  
  def orders
    # TODO - move or orders#index
    @title = "Purchase Orders"
    @sort_order =" PO date - descending order"
    @tag_collection = ["PO Released", "For Delivery", "For-Delivery"]
    # initiate_list
    @all_orders = Order.where(:status =>  @tag_collection)
    @search = @all_orders.search(params[:search])
    if params[:status]
      @orders = Order.where(:status => params[:status]).desc.inclusions_for_admin.paginate :page => params[:page], :per_page => 10
    else
      @orders = @search.desc.inclusions_for_admin.paginate :page => params[:page], :per_page => 10    
    end
    # render 'orders/index'  
  end
  
  def payments
    @title = "Delivered Orders - For Payment"
    @sort_order =" due date (per vehicle) - ascending order"
 
    @all_orders = Order.total_delivered.payment_pending
    @search = @all_orders.by_this_buyer(params[:buyer]).by_this_seller(params[:seller]).search(params[:search]).asc
    @orders = @search.inclusions_for_admin.with_ratings.paginate :page => params[:page], :per_page => 10   

    @buyers = @all_orders.collect(&:company_id).uniq.collect { |buyer| [Company.find(buyer).name, admin_payments_path(:buyer => buyer)] }
    @buyers.push(['All', admin_payments_path(:buyer => nil)]) unless @buyers.blank?
    @buyers_path = admin_payments_path(:buyer => params[:buyer]) 

    @sellers = @all_orders.collect(&:seller_id).uniq.collect { |seller| [User.find(seller).company_name, admin_payments_path(:seller => seller)] }
    @sellers.push(['All', admin_payments_path(:seller => nil)]) unless @sellers.blank?
    @sellers_path = admin_payments_path(:seller => params[:seller])
    render 'admin/orders'  
  end
  
  def overdue_reminder
    @overdue_orders = Order.overdue.payment_pending 
    if @overdue_orders
      @overdue_orders.group_by(&:company).each do |company, overdue_orders|
        @powerbuyers = company.users.where(:id => Role.find_by_name('powerbuyer').users).collect { |u| "#{u.profile.full_name} <#{u.email}>" }
        @powerbuyers.each do |powerbuyer|
          OrderMailer.delay.overdue_alert(powerbuyer, overdue_orders)
        end
      end
    end
    redirect_to admin_payments_path, :notice => 'Sent payment reminders to Buyers.'
  end
  
  def due_now_reminder
    @due_now_orders = Order.due_soon.payment_pending
    if @due_now_orders
      @due_now_orders.group_by(&:company).each do |company, due_now_orders|
        @powerbuyers = company.users.where(:id => Role.find_by_name('powerbuyer').users).collect { |u| "#{u.profile.full_name} <#{u.email}>" }
        @powerbuyers.each do |powerbuyer|
          OrderMailer.delay.due_now_alert(powerbuyer, due_now_orders)
        end
      end
    end
    redirect_to admin_payments_path, :notice => 'Sent payment reminders to Buyers.'
  end
  
  def buyer_fees
    @title = "Decline Fees"
    @all_decline_fees = Fee.date_range(params[:start], params[:end], 'i').declined
    start_date # defined in AppController
    end_date
    # @total_bids = Bid.count
    # @percentage_declined = (@all_decline_fees.count.to_f/@total_bids.to_f) * 100

    @search = @all_decline_fees.by_this_buyer(params[:buyer], 'comp').by_this_seller(params[:seller], 'comp').search(params[:search])
    @decline_fees = @search.inclusions.paginate :page => params[:page], :per_page => 30

    @buyers = @all_decline_fees.collect(&:buyer_company_id).uniq.collect { |buyer| [Company.find(buyer).name, admin_buyer_fees_path(:buyer => buyer)] }
    @buyers.push(['All', admin_buyer_fees_path(:buyer => nil)]) unless @buyers.blank?
    @buyers_path = admin_buyer_fees_path(:buyer => params[:buyer]) 

    @sellers = @all_decline_fees.collect(&:seller_company_id).uniq.collect { |seller| [Company.find(seller).name, admin_buyer_fees_path(:seller => seller)] }
    @sellers.push(['All', admin_buyer_fees_path(:seller => nil)]) unless @sellers.blank?
    @sellers_path = admin_buyer_fees_path(:seller => params[:seller])
    @period_path = admin_buyer_fees_path
    render 'buyer/fees'
  end

  def seller_fees
    @title = "Market Fees for Paid Orders"
    @sort_order =" date PO was paid - descending order"
    @all_market_fees = Fee.date_range(params[:start], params[:end]).ordered
    start_date # defined in AppController
    end_date
    @search = @all_market_fees.by_this_seller(params[:seller], 'comp').search(params[:search])
    @market_fees = @search.inclusions.with_orders.paginate :page => params[:page], :per_page => 30

    @sellers = @all_market_fees.collect(&:seller_company_id).uniq.collect { |seller| [Company.find(seller).name, admin_seller_fees_path(:seller => seller)] }
    @sellers.push(['All', admin_seller_fees_path(:seller => nil)]) unless @sellers.blank?
    @sellers_path = admin_seller_fees_path(:seller => params[:seller])
    @period_path = admin_seller_fees_path
    render 'seller/fees'
  end

  def utilities
  end

  def expire_entries
    @entries = Entry.results.unexpired.includes(:line_items) + Entry.online.unexpired.includes(:line_items)
    @entries.each do |entry|
      entry.expire
    end
    flash[:notice] = "Successful"
    redirect_to :back  
  end

  def cleanup
    entries = Entry.results.unexpired#.where(:id => [1866, 1856])#
    for entry in entries
      for item in entry.line_items.with_bids.includes(:bids, :order_item)
        item.update_for_decision
     end
    end
 
    entries = Entry.ordered
    for entry in entries.includes(:line_items)
      for item in entry.line_items.with_bids.includes(:bids, :order_item)
        if item.order_item.present? 
          item.fix_ordered
        # else
        #   item.fix_declined
        end
      end
      entry.update_status
    end
    
    entries = Entry.expired.where('created_at >= ?', 1.month.ago)
    for entry in entries.includes(:line_items)
      for item in entry.line_items.with_bids.includes(:bids, :order_item)
        if item.order_item.present? 
          item.fix_ordered
        else
          item.fix_declined
        end
      end
    entry.update_status
    end
    
    # entries = Entry.all
    # for entry in entries
    #   entry.line_items_count = entry.line_items.count
    #   entry.bids_count = entry.bids.count
    #   entry.company_id = entry.user.company.id
    #   entry.save!
    # end
    # line_items = LineItem.all
    # for item in line_items
    #   item.bids_count = item.bids.count
    #   item.save!
    # end
    # bids = Bid.where(:status => ['Delivered', 'For-Decision', 'Paid', 'Closed'])
    # bids.each do |bid|
    #   bid.update_attributes(:declined => nil, :expired => nil)
    # end
    # orders = Order.paid_and_closed.payment_valid
    # orders.each do |order|
    #   order.bids.each do |bid|
    #     bid.update_attributes(:status => order.status, :paid => order.paid)
    #     if bid.fee.nil?
    #       Fee.compute(bid, bid.status, bid.order_id)
    #     end
    #   end
    # end
    # bids = Bid.declined
    # bids.each do |bid|
    #   if bid.fee.nil?
    #     Fee.compute(bid, bid.status)
    #   end
    # end

    # all_orders = Order.scoped.includes(:order_items, :bids)
    # all_orders.each do |order|
    #   order.order_total = order.bids.collect(&:total).sum
    #   order.order_items_count = order.order_items.count
    #   order.save!
    # end
    
    flash[:notice] = "Successful cleanup"
    redirect_to request.env["HTTP_REFERER"]
  end

  def change_status
    # raise params.to_yaml
    @entry = Entry.find(params[:id])
    @line_items = @entry.line_items
    status =  params[:admin_status]
    if @entry.update_attribute(:buyer_status, status)
      @entry.update_associated_status(status)
      flash[:notice] = ("Changed the status to <strong>#{status}</strong>.").html_safe
    end
    redirect_to :back
  end

  def update_perf_ratios
    for company in Company.all
      if company.primary_role == 2 # buyer
        unless company.entries.blank?
        line_items = LineItem.with_bids.metered.where(:entry_id => company.entries).count
        if line_items > 0
          parts_ordered = company.orders.metered.map{|order| order.order_items.count}.sum
          company.perf_ratio = (BigDecimal("#{parts_ordered}")/BigDecimal("#{line_items}")).to_f * 100
        else
          company.perf_ratio = 0
        end
        end
      elsif company.primary_role == 3 # seller
        parts_bided = company.users.map{|user| user.bids.since_eval(company.evaln).collect(&:line_item_id).uniq.count}.sum
        line_items = LineItem.since_eval(company.evaln).count
        company.perf_ratio = (BigDecimal("#{parts_bided}")/BigDecimal("#{line_items}")).to_f * 100
      end
      company.save!
    end
    flash[:notice] = "Performance Ratios successfully updated!"
    redirect_to request.env["HTTP_REFERER"]
  end

private
  
  def get_stats
    @presenter = AdminPresenter.new(current_user)
    @line_items = LineItem.scoped
      @li_all = @line_items.count
      @li_m = @line_items.metered.count
      @li_f = @line_items.ftm.count
    @bids = Bid.order('bid_speed asc')#ascend_by_bid_speed
      @ob_all = @bids.collect(&:line_item_id).uniq.count
      @ob_all_pct = (@ob_all.to_f / @li_all.to_f) * 100
      @ob_m = @bids.metered.collect(&:line_item_id).uniq.count
      @ob_m_pct = (@ob_m.to_f / @li_m.to_f) * 100
      @ob_f = @bids.ftm.collect(&:line_item_id).uniq.count
      @ob_f_pct = (@ob_f.to_f / @li_f.to_f) * 100
      @ob2_all = @line_items.two_and_up.count
      @ob2_all_pct = (@ob2_all.to_f / @li_all.to_f) * 100
      @ob2_m = @line_items.two_and_up.metered.count
      @ob2_m_pct = (@ob2_m.to_f / @li_m.to_f) * 100
      @ob2_f = @line_items.two_and_up.ftm.count
      @ob2_f_pct = (@ob2_f.to_f / @li_f.to_f) * 100
    @missed = @li_all -  @ob_all
      @msd_all_pct = (@missed.to_f / @li_all.to_f) * 100
      @msd_m = @li_m - @ob_m
      @msd_m_pct = (@msd_m.to_f / @li_m.to_f) * 100
      @msd_f = @li_f - @ob_f
      @msd_f_pct = (@msd_f.to_f / @li_f.to_f) * 100
    @total_bids =  @bids.count
      @tb_m = @bids.metered.count
      @tb_f = @bids.ftm.count
    @orig = @bids.orig
      @orig_all = @orig.count
      @orig_m = @orig.metered.count
      @orig_f = @orig.ftm.count
    @rep = @bids.rep
      @rep_all = @rep.count
      @rep_m = @rep.metered.count
      @rep_f = @rep.ftm.count
    @surp = @bids.surp
      @surp_all = @surp.count
      @surp_m = @surp.metered.count
      @surp_f = @surp.ftm.count
    # @ordered = OrderItem.order_seller_id_eq(current_user)
    @ordered = Order.scoped
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
    @pending = @bids.where(:status => 'For-Decision')
      @fdec_all = @pending.count
      @fdec_m = @pending.metered.count
      @fdec_f = @pending.ftm.count
    @declined = @bids.where(:status => 'Declined')
      @decl_all = @declined.count
      @decl_m = @declined.metered.count
      @decl_f = @declined.ftm.count
    @lose = @bids.where(:status => ['Lose', 'Dropped', 'Expired'])
      @lose_all = @lose.count
      @lose_m = @lose.metered.count
      @lose_f = @lose.ftm.count
    @new = @bids.where(:status => ['Submitted', 'Updated'])
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
    @own_orders = @ebid_orders
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
      
      @speed = Bid.ftm.where('bid_speed > ?', 1).order(:bid_speed)
  end
end
