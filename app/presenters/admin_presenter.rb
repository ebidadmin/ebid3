class AdminPresenter
  extend ActiveSupport::Memoizable
  
  def initialize(user)
    @user = user
  end
  
  def line_items
   LineItem.scoped
  end
  
  def bids
    Bid.order(:bid_speed)
  end
  
  def orders
    Order.scoped
  end
  
  def li_all
    line_items.count
  end
  
  def li_m
    line_items.metered.count
  end
  
  def li_f
    line_items.ftm.count
  end
  
  def uniq_bids
    bids.collect(&:line_item_id).uniq.count
  end
  
  def uniq_bids_pct
    (uniq_bids.to_f/li_all.to_f) * 100
  end
  
  def uniq_bids_m
    bids.metered.collect(&:line_item_id).uniq.count
  end
  
  def uniq_bids_m_pct
    (uniq_bids_m.to_f/li_m.to_f) * 100
  end
  
  def uniq_bids_f
    bids.ftm.collect(&:line_item_id).uniq.count
  end
  
  def uniq_bids_f_pct
    (uniq_bids_f.to_f/li_f.to_f) * 100
  end

  def two_and_up
    line_items.two_and_up.count
  end
  
  def two_and_up_pct
    (two_and_up.to_f/li_all.to_f) * 100
  end
  
  def two_and_up_m
    line_items.two_and_up.metered.count
  end
  
  def two_and_up_m_pct
    (two_and_up_m.to_f/li_m.to_f) * 100
  end
  
  def two_and_up_f
    line_items.two_and_up.ftm.count
  end
  
  def two_and_up_f_pct
    (two_and_up_f.to_f/li_f.to_f) * 100
  end

  def total_bids
    bids.count
  end
  
  def total_bids_m
    bids.metered.count
  end
  
  def total_bids_f
    bids.ftm.count
  end

  def bids_orig
    bids.orig
  end

  def bids_rep
    bids.rep
  end

  def bids_surp
    bids.surp
  end

  def bids_w_orders_all
    # orders.count
  end
  
  def bids_w_orders_pct
    (orders.count.to_f/uniq_bids.to_f) * 100
  end
  
  def bids_w_orders_m
    orders.metered
  end
  
  def bids_w_orders_m_pct
    (bids_w_orders_m.count.to_f/uniq_bids.to_f) * 100
  end
  
  def bids_w_orders_f
    orders.ftm
  end

  def bids_w_orders_f_pct
    (bids_w_orders_f.count.to_f/uniq_bids.to_f) * 100
  end

  def days_m
    (Time.now.to_date - Company::OFFICIAL_METERING_DATE).to_f
  end
  
  def average_bids_m
    (total_bids_m/days_m).round(2)
  end
  
  def days_f
    unless Date.today  == Time.now.beginning_of_month.to_date # this condition prevents zero divisor
      (Time.now.to_date - Time.now.beginning_of_month.to_date).to_f
    else
      1
    end
  end
  
  def average_bids_f
    unless Date.today  == Time.now.beginning_of_month.to_date # this condition prevents zero divisor
      (total_bids_f/days_f).round(2)
    else
      total_bids_f.round(2)
    end
  end
  
  def bids_w_orders_amount
    orders.collect(&:order_total).sum
  end

  def bids_w_orders_m_amount
    bids_w_orders_m.collect(&:order_total).sum
  end

  def bids_w_orders_f_amount
    bids_w_orders_f.collect(&:order_total).sum
  end
  
  def new_orders
    orders.recent
  end
  
  def new_orders_all
    new_orders.collect(&:order_total).sum
  end
  
  def new_orders_m
    new_orders.metered.collect(&:order_total).sum
  end
  
  def new_orders_f
    new_orders.ftm.collect(&:order_total).sum
  end
 
  memoize :line_items, :bids, :orders, :li_all, :li_m, :li_f, :uniq_bids, :uniq_bids_m, :uniq_bids_f,
  :two_and_up, :two_and_up_m, :two_and_up_f, :total_bids, :total_bids_m, :total_bids_f, :bids_orig, :bids_rep, :bids_surp, 
  :bids_w_orders_all, :bids_w_orders_m, :bids_w_orders_f, :bids_w_orders_amount, :bids_w_orders_m_amount, :bids_w_orders_f_amount,
  :new_orders
end