class BuyerController < ApplicationController

  def main
    @title = "Buyer's Dashboard"
    if current_user.has_role?("powerbuyer")
      initiate_list
      delivered = Order.where(:company_id => current_user.company).delivered
      due_soon = delivered.due_soon
      @due_soon_count = due_soon.count
      @due_soon_amount = due_soon.collect(&:total_order_amounts).sum
      overdue_payments = delivered.overdue
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
    @status = "Online"
    find_entries
    @search = @finder.current.desc.search(params[:search])
    @entries = @search.paginate(:page => params[:page], :per_page => 10)
    render 'entries/index'  
  end

  def results
    @title = 'Bidding Results'
    @tag_collection = ["For Decision", "Ordered-IP", "Declined-IP"]
    initiate_list
    find_entries
    @search = @finder.current.asc.search(params[:search])
    @entries = @search.paginate(:page => params[:page], :per_page => 10)
    render 'entries/index'  
  end
  
  def orders
    @title = 'Orders'
    @tag_collection = ["PO Released", "For Delivery"]
    initiate_list
    find_orders
    @search = @all_orders.desc.search(params[:search])
    @orders = @search.paginate :page => params[:page], :per_page => 10    
    render 'orders/index'  
  end

  def payments
    @title = 'Delivered Orders - For Payment'
    initiate_list
    @status = "Delivered"
    find_orders
    @search = @all_orders.asc.search(params[:search])    
    @orders = @search.paginate :page => params[:page], :per_page => 10    
    render 'orders/index'  
  end

  def paid
    @title = 'Paid Orders - For Rating'
    initiate_list
    @status = "Paid"
    find_orders
    @search = @all_orders.asc.search(params[:search])
    @orders = @search.paginate :page => params[:page], :per_page => 10    
    render 'orders/index'  
  end

  def fees
    @title = "Declined Winning Bids"
    initiate_list
    if params[:user_id] == 'all'
      entries = Entry.where(:user_id => current_user.company.users)
      @total_bids = entries.collect(&:bids_count).sum
      @all_declined_bids = Bid.where(:entry_id => entries).declined
    else
      entries = defined_user.entries
      @total_bids = Entry.where(:id => entries).(&:bids_count).sum
      @all_declined_bids = Bid.where(:entry_id => entries).declined
    end
    @percentage_declined = (@all_declined_bids.count.to_f/@total_bids.to_f) * 100
    @declined_bids = @all_declined_bids.paginate :page => params[:page], :per_page => 20

    # @declined_bids = Bid.where(:entry_id => current_user.entries).declined.paginate :page => params[:page], :per_page => 20
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
    @total = entries.count
    @pending = entries.pending.count
    @online = entries.online.current.count
    @decision = entries.results.current.count
    @expired = entries.where(:buyer_status => 'Expired').count
    @expired2 = entries.online.expired.count
    @expired3 = entries.results.expired.count
    @declined = entries.declined.count
    @closed = entries.closed.count
    @orders = orders.count
    @released = orders.recent.count
    delivered_items =  orders.delivered
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
    o_paid = orders.paid
    @paid_count = o_paid.count
    @paid_amount = o_paid.collect(&:total_order_amounts).sum
  end
  
end
