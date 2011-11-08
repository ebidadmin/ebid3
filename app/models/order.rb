class Order < ActiveRecord::Base
  require 'date'

  belongs_to :user
  belongs_to :seller, :class_name => "User"
  
  belongs_to :entry
  accepts_nested_attributes_for :entry
  belongs_to :company
  has_many :order_items
  has_many :line_items, :through => :order_items  
  has_many :ratings
  has_many :bids
  has_many :fees
  has_many :messages
  accepts_nested_attributes_for :messages
 
  validates_presence_of :deliver_to, :address1, :phone

  scope :inclusions, includes([:entry => [:car_brand, :car_model, :car_variant, :user]], :company, [:seller => :company], [:order_items => [:line_item => :car_part]])
  scope :inclusions_for_seller, includes([:entry => [:car_brand, :car_model, :car_variant, :user]], :company, [:order_items => [:line_item => :car_part]])
  scope :inclusions_for_admin, includes([:entry => [:car_brand, :car_model, :car_variant]], :company, [:seller => :company], [:order_items => [:line_item => :car_part]])
  scope :with_ratings, includes(:ratings => :user)
  
  scope :desc, order('id desc')
  scope :asc, order('delivered')
  scope :desc2, order('pay_until desc')
  scope :asc2, order('paid')

  scope :unpaid, where(:paid => nil)

  scope :recent, where(:status => ['PO Released', 'For-Delivery', 'For Delivery'])
  scope :total_delivered, where(:status => ['Delivered', 'Paid', 'Closed'])
  scope :delivered, where(:status => 'Delivered')
  scope :paid, where(:status => 'Paid').asc2
  scope :closed, where(:status => 'Closed')
  scope :paid_and_closed, where(:status => ['Paid', 'Closed']).order('paid desc')
  scope :payment_valid, where('orders.paid IS NOT NULL')
  scope :payment_pending, where('orders.paid IS NULL')
  scope :not_cancelled, where('orders.status NOT LIKE ?', "%Cancelled%") # used in Orders#Show

  scope :needs_confirmation, paid.payment_pending
  scope :needs_rating, paid.payment_valid
  
  scope :within_term, delivered.where('pay_until >= ?', Date.today)
  scope :due_soon, delivered.where(:pay_until => Date.today .. 1.week.from_now.to_date).unpaid
  scope :overdue, delivered.where('pay_until < ?', Date.today)
  
  scope :for_auto_rating, where('ratings_count < ?', 2)

  scope :metered, where('orders.created_at >= ?', '2011-04-16')
  scope :ftm, where('orders.created_at >= ?', Time.now.beginning_of_month)
 
  def self.by_this_seller(id, indicator = nil)
    if id.present?
      where(:seller_id => id)
    else
      scoped
    end
  end

  def self.by_this_buyer(id)
    if id.present?
      where(:company_id => id)
    else
      scoped
    end
  end

  def initialize_order(user, user_bids, seller, ip)
    self.company_id = user.company.id
    self.buyer_ip = ip
    self.seller_id = seller
    OrderItem.populate(self, user_bids)
    self.order_total = user_bids.collect(&:total).sum
  end
    
  # Updates line_items & bids to status = For Delivery, Delivered, or Paid
	def update_associated_status(status)
    order_items.each do |item|
      item.line_item.update_attribute(:status, status)
    end
    if status == "Delivered"
      bids.update_all(:status => status, :delivered => Date.today)
    elsif status == "Paid"
      bids.update_all(:status => status, :paid => Date.today)
      bids.each do |bid|
        if bid.fee.nil?
          Fee.compute(bid, status, self.id)
        end
      end
    else 
      bids.update_all(:status => status)
    end
	end
  
  def total_order_amounts
    bids.collect(&:total).sum
  end

  def self.search(search)  
    if search  
      finder = Entry.where('plate_no LIKE ? ', "%#{search}%") 
      where(:entry_id => finder)
    else  
      scoped  
    end  
  end  

  def self.search_orders(params = nil, seller = nil, sort_order = nil)
    if seller
      self.where(:seller_id => seller).order(sort_order).search(params) 
    else
      self.order(sort_order).search(params) 
    end
  end
  
  def has_ratings?(users) # used in ORDERS#INDEX
    ratings.where(:user_id => users).exists?
  end
  
  def days_overdue # used in ORDERS#INDEX
    (Date.today - pay_until).to_i - 1
  end
  
  def paid_but_overdue # used in ORDERS#SHOW
    (paid - pay_until).to_i 
  end

  def days_ordered
    (Time.now - confirmed).to_i - 1
  end
  
  def days_to_deliver # used in RATINGS#FORM
    (delivered - created_at.to_date).to_i 
  end
  
  def days_to_pay # used in RATINGS#FORM
    (paid - delivered).to_i
  end
  
  def days_not_rated1 # used in RATINGS#AUTO
    (Date.today - delivered).to_i - 1
  end

  def days_not_rated2 # used in RATINGS#AUTO
    (Date.today - paid).to_i - 1
  end
  
  def prompt_payment?
    (paid - pay_until).to_i 
  end
  
  def compute_rating_for_buyer
    if prompt_payment? > 60
      0
    elsif prompt_payment? > 45
      1
    elsif prompt_payment? > 30
      2
    elsif prompt_payment? > 15
      4
    elsif prompt_payment? <= 15
      5
    else
      3.5
    end
  end
  
  def compute_rating_for_seller
    if days_to_deliver > 7
      0
    elsif days_to_deliver > 5
      1
    elsif days_to_deliver > 3
      2
    elsif days_to_deliver > 2
      3
    elsif days_to_deliver > 1
      4
    elsif days_to_deliver <= 1
      5
    else
      3.5
    end
  end
  
  def can_be_cancelled?(user)
    if user.id == 1
      true
    # elsif user.has_role?('seller')
    #   status == 'PO Released' || status == 'For-Delivery'
    else
      # status == 'PO Released'
      status == 'PO Released' || status == 'For-Delivery'
    end
  end
  
  def cancelled?
    status == 'Cancelled by buyer' || status == 'Cancelled by seller' || status == 'Cancelled by admin'
  end
 
  def close
    update_attribute(:status, "Closed")
    # entry.update_attribute(:buyer_status, "Closed")
    update_associated_status("Closed")
  end
  
  def revert
    update_attribute(:status, "Paid")
    update_associated_status("Paid")
  end

  def self.since_eval(date)
    where('orders.created_at >= ?', date)
  end
  
  def days_late
    weekdays_in_date_range( self.confirmed.to_date..(Date.today) )
  end
  
  def weekdays_in_date_range(range)
    range.select { |d| (1..5).include?(d.wday) }.size
  end
end
