class Fee < ActiveRecord::Base
  attr_accessible :buyer_company_id, :buyer_id, :seller_company_id, :seller_id, :entry_id, :line_item_id, :order_id,
  :bid_id, :bid_total, :bid_type, :fee, :fee_type, :remitted, :split_amount, :split_date, :bid_speed, :fee_rate, :order_paid,
  :perf_ratio
  
  belongs_to :buyer_company, :class_name => "Company"
  belongs_to :seller_company, :class_name => "Company"
  belongs_to :buyer, :class_name => "User"
  belongs_to :seller, :class_name => "User"
  belongs_to :entry
  belongs_to :line_item
  belongs_to :order
  belongs_to :bid
  
  scope :ordered, where(:fee_type => 'Ordered').order('order_paid DESC')
  scope :declined, where(:fee_type => ['Declined', 'Expired', 'Expired-Rvsd', 'Reverted', 'Reversed']).order('created_at DESC')
  scope :inclusions, includes([:entry => [:car_brand, :car_model, :car_variant, :user]], [:line_item => :car_part], :seller )
  scope :with_orders, includes(:order)
  
  scope :metered, where('fees.created_at >= ?', '2011-04-16')
  
  def self.search(search)  
    if search  
      finder = Entry.where('plate_no LIKE ? ', "%#{search}%") 
      where(:entry_id => finder)
    else  
      scoped  
    end  
  end  
  
  def self.date_range(start_date = nil, end_date = nil, indicator = nil)
    unless indicator.present?
      if end_date.present?
        where(:order_paid => start_date..end_date)
      elsif start_date.present?
        where(:order_paid => start_date..Date.today)
      else
        where('fees.order_paid >= ?', Date.today.beginning_of_month)
      end
    else
      if end_date.present?
        where(:created_at => start_date..end_date)
      elsif start_date.present?
        where(:created_at => start_date..Date.today)
      else
        where('fees.created_at >= ?', Date.today.beginning_of_month)
      end
    end
  end

  def self.by_this_seller(id, indicator = nil)
    if id.present?
      if indicator == 'comp'
        where(:seller_company_id => id)
      else
        where(:seller_id => id)
      end
    else
      scoped
    end
  end

  def self.by_this_buyer(id, indicator = nil)
    if id.present?
      if indicator == 'comp'
        where(:buyer_company_id => id)
      else     
        where(:buyer_id => id)
      end
    else
      scoped
    end
  end

  def self.compute(bid, status, order=nil)
    f = Fee.new
    f.buyer_company_id = bid.entry.user.company.id
    f.buyer_id = bid.entry.user_id
    f.seller_company_id = bid.user.company.id
    f.seller_id = bid.user_id
    f.entry_id = bid.entry_id
    f.line_item_id = bid.line_item_id
    f.bid_id = bid.id
    f.bid_total = bid.total
    f.bid_type = bid.bid_type
    f.bid_speed = bid.bid_speed 
    if status == 'Paid' || status == 'Closed' # Market Fees
      f.fee_type = 'Ordered'
      f.order_id = order if order
      f.created_at = bid.paid if bid.paid
      f.order_paid = f.order.paid.to_date
      ratio = f.seller_company.perf_ratio
      if ratio < 70
        f.fee_rate = 3.5 - f.seller_discount
      elsif ratio < 80         
        f.fee_rate = 3.0 - f.seller_discount
      elsif ratio >= 80       
        f.fee_rate = 2.0 - f.seller_discount
      end
      f.fee = f.bid_total * (f.fee_rate.to_f/100)
      f.perf_ratio = ratio
    else                                      # Decline Fees
      # f.fee = bid.total * 0.0025
      # f.split_amount = f.fee/2
      if bid.expired
        f.created_at = bid.expired
        f.fee_type = 'Expired'
      else
        f.created_at = bid.declined
        f.fee_type = 'Declined'
      end
      ratio = f.buyer_company.perf_ratio
      if ratio < 10
        f.fee_rate = 0.5 - f.buyer_discount(0.5).to_f
      elsif ratio < 30
        f.fee_rate = 0.375 - f.buyer_discount(0.375).to_f
      elsif ratio < 50
        f.fee_rate = 0.25 - f.buyer_discount(0.25).to_f
      elsif ratio >= 50
        f.fee_rate = 0
      end
      f.fee = f.bid_total * (f.fee_rate.to_f/100)
      f.split_amount = f.fee/2 
      f.perf_ratio = ratio
    end
    f.save
  end
  
  def seller_discount
    if bid.bid_speed < 4.hours
      0.5
    elsif bid.bid_speed <= 8.hours
      0.25
    else
      0
    end 
  end
  
  def buyer_discount(base_rate)
    unless bid.blank?
      if bid.bid_speed < 4.hours
        0
      elsif bid.bid_speed <= 8.hours
        base_rate * 0.25
      elsif bid.bid_speed <= 2.days
        base_rate * 0.50
      elsif bid.bid_speed > 2.days
        base_rate * 1.00
      end 
    end
  end

  def reverse
    update_attribute(:fee_type, fee_type + '-Rvsd') unless self.reversed?
    f = Fee.new(self.attributes)
    # f.buyer_company_id = self.buyer_company_id
    # f.buyer_id = self.buyer_id
    # f.seller_company_id = self.seller_company_id
    # f.seller_id = self.seller_id
    # f.entry_id = self.entry_id
    # f.line_item_id = self.line_item_id
    # f.bid_id = self.bid_id
    f.bid_type = f.bid_speed = f.perf_ratio = f.fee_rate = nil
    f.bid_total = 0
    f.fee = 0 - self.fee
    f.fee_type = 'Reversed'
    f.created_at = Time.now.to_date
    f.split_amount = 0 - self.split_amount
    f.save
  end
  
  def reversed?
    fee_type == 'Expired-Rvsd'
  end
end
