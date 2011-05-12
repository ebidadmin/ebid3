class AdminController < ApplicationController
  def index
    @title = 'Admin Dashboard'
    @entries = Entry.scoped
    @line_items = LineItem.where('created_at > ?', 6.months.ago)
    @with_bids = @line_items.with_bids
    @with_bids_pct = @line_items.with_bids_pct
    @two_and_up = @line_items.two_and_up
    @two_and_up_pct = @line_items.two_and_up_pct
    @without_bids = @line_items.without_bids
    @with_order = OrderItem.all.collect(&:line_item_id).uniq.count
    @with_order_pct = (@with_order.to_f/@with_bids.count.to_f) * 100
    @orders = Order.scoped.collect(&:total_order_amounts).sum
    @paid = Order.paid_and_closed.payment_valid.collect(&:total_order_amounts).sum

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
    @entries = @search.desc.includes(:user, :car_brand, :car_model, :car_variant, :term, :city, :bids, :orders, :photos).paginate(:page => params[:page], :per_page => 10)
    render 'entries/index'
  end

  def online
    @title = "What's Online?"
    @search = Entry.online.current.order('bid_until DESC').search(params[:search])
    @entries = @search.paginate(:page => params[:page], :per_page => 10)
    render 'entries/index'  
  end

  def bids
    bids = Bid.desc
    @brand_links = CarBrand.find(bids.collect(&:car_brand_id).uniq)
    if params[:brand] == 'all'
      @search = bids.search(params[:search])
    elsif params[:brand]
      brand = CarBrand.find_by_name(params[:brand])
      @search = bids.where(:car_brand_id => brand).search(params[:search])
    else
      @search = bids.search(params[:search])
    end
    @bids = @search.inclusions.paginate :page => params[:page], :per_page => 20    
    render 'bids/index' 
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
 
    @all_orders = Order.delivered.asc
    if params[:seller]
      @search = @all_orders.where(:seller_id => params[:seller]).asc.search(params[:search]) 
    else
      @search = @all_orders.search(params[:search])
    end  
    @orders = @search.inclusions_for_admin.with_ratings.paginate :page => params[:page], :per_page => 10   

    @sellers = @all_orders.collect(&:seller_id).uniq.collect { |seller| [User.find(seller).company_name, admin_payments_path(:seller => seller)] }
    @sellers.push(['All', admin_payments_path(:seller => nil)]) unless @sellers.blank?
    @sellers_path = admin_payments_path(:seller => params[:seller])
    render 'admin/orders'  
  end
  
  def buyer_fees
    @title = "Decline Fees"
    @all_decline_fees = Fee.declined
    @total_bids = Bid.count
    @percentage_declined = (@all_decline_fees.count.to_f/@total_bids.to_f) * 100
    if params[:buyer]
      @search = @all_decline_fees.where(:buyer_company_id => params[:buyer]).search(params[:search])
    else
      @search = @all_decline_fees.search(params[:search])
    end
    # if params[:seller]
    #   @search = @all_decline_fees.where(:seller_company_id => params[:seller]).search(params[:search])
    # else
    #   @search = @all_decline_fees.search(params[:search])
    # end
    @decline_fees = @search.inclusions.paginate :page => params[:page], :per_page => 30
    @group = @decline_fees.group_by(&:entry)

    @buyers = @all_decline_fees.collect(&:buyer_company_id).uniq.collect { |buyer| [Company.find(buyer).name, admin_buyer_fees_path(:buyer => buyer)] }
    @buyers.push(['All', admin_buyer_fees_path(:buyer => nil)]) unless @buyers.blank?
    @buyers_path = admin_buyer_fees_path(:buyer => params[:buyer])

    @sellers = @all_decline_fees.collect(&:seller_company_id).uniq.collect { |seller| [Company.find(seller).name, admin_buyer_fees_path(:seller => seller)] }
    @sellers.push(['All', admin_buyer_fees_path(:seller => nil)]) unless @sellers.blank?
    @sellers_path = admin_buyer_fees_path(:seller => params[:seller])
  end

  def seller_fees
    @title = "Market Fees for Paid Orders"
    @sort_order =" date PO was paid - descending order"
    @all_market_fees = Fee.ordered
    if params[:seller]
      @search = @all_market_fees.where(:seller_company_id => params[:seller]).search(params[:search])
    else
      @search = @all_market_fees.search(params[:search])
    end
    @market_fees = @search.inclusions.with_orders.paginate :page => params[:page], :per_page => 30

    @sellers = @all_market_fees.collect(&:seller_company_id).uniq.collect { |seller| [Company.find(seller).name, admin_seller_fees_path(:seller => seller)] }
    @sellers.push(['All', admin_seller_fees_path(:seller => nil)]) unless @sellers.blank?
    @sellers_path = admin_seller_fees_path(:seller => params[:seller])
  end

  def utilities
    
  end

  def expire_entries
    @entries = Entry.online.current.includes(:line_items) + Entry.results.current.includes(:line_items)
    @entries.each do |entry|
      entry.expire
    end
    flash[:notice] = "Successful"
    redirect_to :back  
    # render 'entries/index'
  end

  def cleanup
    entries = Entry.all
    for entry in entries
      entry.line_items_count = entry.line_items.count
      entry.bids_count = entry.bids.count
      entry.company_id = entry.user.company.id
      entry.save!
    end
 
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
    # all_orders = Order.find(:all, :include => :bids)
    # all_orders.each do |order|
    #   order.update_attribute(:order_total, order.bids.collect(&:total).sum)
    # end
    
    flash[:notice] = "Successful cleanup"
    redirect_to request.env["HTTP_REFERER"]
  end

end
