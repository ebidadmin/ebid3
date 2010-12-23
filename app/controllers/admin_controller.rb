class AdminController < ApplicationController
  def index
    @title = 'Admin Dashboard'
    @entries = Entry.scoped
    @line_items = LineItem.scoped
    @with_bids = @line_items.with_bids
    @with_bids_pct = @line_items.with_bids_pct
    @two_and_up = @line_items.two_and_up
    @two_and_up_pct = @line_items.two_and_up_pct
    @without_bids = @line_items.without_bids

    @online_entries =  @entries.online.current.desc.five 
    @users = User.active
    # @order = Order.all
  end

  def entries
    @title = 'All Entries'
    @user_group = Role.find_by_name('buyer').users.order('username').collect { |user| [user.username_for_menu, admin_entries_path(:user_id => user.username.downcase)] }
    @user_group.push(['All', admin_entries_path(:user_id => 'all')])
    @current_path = admin_entries_path(params[:user_id])
    entries = Entry.scoped
    
    if params[:user_id] == 'all'
      @search = entries.search(params[:search])
    else
      @search = entries.where(:user_id => User.find_by_username(params[:user_id])).search(params[:search])
    end
    @entries = @search.desc.paginate(:page => params[:page], :per_page => 10)
    render 'entries/index'
  end

  def online
    @title = "What's Online?"
    @search = Entry.online.current.order('bid_until DESC').search(params[:search])
    @entries = @search.paginate(:page => params[:page], :per_page => 10)
    render 'entries/index'  
  end

  def bids
    @search = Bid.desc.search(params[:search])
    @bids = @search.paginate :page => params[:page], :per_page => 10    
    render 'bids/index' 
  end
  
  def orders
    @title = "Purchase Orders"
    @sort_order =" PO date - descending order"
    @all_orders = Order.recent
    @search = @all_orders.search(params[:search])
    @orders = @search.desc.paginate :page => params[:page], :per_page => 10    
    if params[:status]
      @orders = Order.where(:status => params[:status]).desc.paginate :page => params[:page], :per_page => 10
    end
    render 'orders/index'  
  end
  
  def payments
    @title = "Delivered Orders - For Payment"
    @sort_order =" due date (per vehicle) - ascending order"
    @sellers = Role.find_by_name('seller').users.order('username').collect { |seller| [seller.company_name, admin_payments_path(:seller => seller.id)]}
    @sellers.push(['All', admin_payments_path(:seller => nil)]) unless @sellers.blank?
    @sellers_path = admin_payments_path(:seller => params[:seller])
 
    @all_orders = Order.delivered.unpaid.asc
    @search = @all_orders.search(params[:search])
    @search = @all_orders.where(:seller_id => params[:seller]).asc.search(params[:search]) unless params[:seller].nil?
    @orders = @search.paginate :page => params[:page], :per_page => 10    
    render 'orders/index'  
  end
  
  def buyer_fees
    @title = "Declined Winning Bids"
    @total_bids = Bid.count
    @all_declined_bids = Bid.declined
    @percentage_declined = (@all_declined_bids.count.to_f/@total_bids.to_f) * 100
    @declined_bids = @all_declined_bids.paginate :page => params[:page], :per_page => 20
    render 'buyer/fees'
  end

  def supplier_fees
    @title = "Transaction Fees for Paid Orders"
    @sort_order =" date PO was paid - descending order"
    @all_orders = Order.paid_and_closed
    @orders = @all_orders.paginate :page => params[:page], :per_page => 10
    render 'seller/fees'
  end

  def utilities
    
  end

  def expire_entries
    @entries = Entry.results.includes(:line_items).first
    # @entries.each do |entry|
    #   # entry.expire_online_entry
    #   entry.expire
    # end
    flash[:notice] = "Successful"
    redirect_to :back  
    # render 'entries/index'
  end
end
