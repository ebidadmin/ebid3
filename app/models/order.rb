class Order < ActiveRecord::Base
  
  require 'date'
  belongs_to :user
  belongs_to :seller, :class_name => "User"
  
  belongs_to :entry
  belongs_to :company
  has_many :order_items
  has_many :line_items, :through => :order_items  
  has_many :ratings
  has_many :bids
 
  validates_presence_of :deliver_to, :address1, :phone

  scope :desc, order('id DESC')
  scope :asc, order('delivered')
  scope :desc2, order('pay_until DESC')
  scope :asc2, order('paid')

  scope :unpaid, where(:paid => nil)

  scope :recent, where("status IN ('PO Released', 'For-Delivery', 'For Delivery')")
  scope :total_delivered, where("status IN ('Delivered', 'Paid', 'Closed')")
  scope :delivered, where(:status => 'Delivered')
  scope :paid, where(:status => 'Paid').asc2
  scope :closed, where(:status => 'Closed')
  scope :paid_and_closed, where("status IN ('Paid', 'Closed')").order('paid DESC')
  scope :payment_valid, where('paid IS NOT NULL')

  scope :within_term, delivered.where('pay_until > ?', Date.today)
  scope :due_soon, delivered.where(:pay_until => Date.today .. Date.today + 1.week).unpaid
  scope :overdue, delivered.where('pay_until < ?', Date.today)
  
  scope :for_auto_rating, where('ratings_count < ?', 2)
 
  def self.by_this_seller(user)
    where(:seller_id => user)
  end

  def initialize_order(user, seller, ip)
    self.company_id = user.company.id
    self.buyer_ip = ip
    self.seller_id = seller
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
        bid.update_attribute(:fee, bid.total * 0.035)
      end
    else 
      bids.update_all(:status => status)
    end
	end
  
  def total_order_amounts
    bids.collect(&:total).sum
  end
  
  def total_success_fees
    bids.collect(&:fee).sum
  end
  
  def self.search(search)  
    if search  
      finder = Entry.where('plate_no LIKE ? ', "%#{search}%") 
      where(:entry_id => finder)
    else  
      scoped  
    end  
  end  
  
  def days_overdue # used in ORDERS#INDEX
    (Date.today - pay_until).to_i - 1
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
      1
    elsif prompt_payment? > 45
      2
    elsif prompt_payment? > 30
      3
    elsif prompt_payment? <= 30
      4
    else
      3.5
    end
  end
  
  def compute_rating_for_seller
    if days_to_deliver > 7
      1
    elsif days_to_deliver > 5
      2
    elsif days_to_deliver > 3
      3
    elsif days_to_deliver <= 3
      4
    else
      3.5
    end
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

end
