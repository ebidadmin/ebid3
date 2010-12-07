class Order < ActiveRecord::Base

  belongs_to :user
  belongs_to :seller, :class_name => "User"
  
  belongs_to :entry
  belongs_to :company
  has_many :order_items
  has_many :line_items, :through => :order_items  
  # has_many :ratings
  has_many :bids
 
  validates_presence_of :deliver_to, :address1, :phone

  scope :desc, order('id DESC')
  scope :asc, order('pay_until')
  scope :desc2, order('pay_until DESC')

  scope :unpaid, where(:paid => nil)

  scope :recent, where("status IN ('PO Released', 'For Delivery')")
  scope :total_delivered, where("status IN ('Delivered', 'Paid', 'Closed')")
  scope :delivered, where(:status => 'Delivered')
  scope :paid, where(:status => 'Paid')
  scope :closed, where(:status => 'Closed')
  scope :paid_and_closed, where("status IN ('Paid', 'Closed')").order('paid DESC')

  scope :within_term, delivered.where('pay_until > ?', Date.today)
  scope :due_soon, delivered.where(:pay_until => Date.today .. Date.today + 1.week).unpaid
  scope :overdue, delivered.where('pay_until < ?', Date.today)
  
 
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
  
  
end
