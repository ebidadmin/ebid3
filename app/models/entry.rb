class Entry < ActiveRecord::Base
  attr_accessible :user_id, :ref_no, :year_model, :car_brand_id, :car_model_id, :car_variant_id, :plate_no, :serial_no, :motor_no, :date_of_loss, 
    :city_id, :new_city, :term_id, :photos_attributes, :bid_until, :buyer_status, :chargeable_expiry, :expired
    
  attr_accessor :new_city
  before_save :create_new_city

  belongs_to :user, :counter_cache => true

  belongs_to :car_brand
  belongs_to :car_model
  belongs_to :car_variant
  belongs_to :city
  belongs_to :term

  has_many :photos, :dependent => :destroy
  accepts_nested_attributes_for :photos, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true

  has_many :line_items, :dependent => :destroy
  has_many :car_parts, :through => :line_items
  has_many :bids, :dependent => :destroy
  has_many :orders
  has_many :order_items, :through => :orders
  has_many :comments, :dependent => :destroy

  validates_presence_of :year_model, :car_brand, :car_model, :plate_no, :serial_no, :motor_no, :term
  validates_presence_of :city, :if => :new_city_blank
  validates_associated :city

  scope :desc, order('id DESC')
  scope :asc, order('bid_until')
  scope :five, limit(5)

  scope :current, where(:expired => nil)
  scope :expired, where('expired IS NOT NULL')

  scope :pending, where("buyer_status IN ('New', 'Edited')")
  scope :online, where("buyer_status = ?", 'Online')
  scope :results, where("buyer_status IN ('For Decision', 'Ordered-IP', 'Declined-IP')")
  scope :declined, where('buyer_status LIKE ?', "%Declined%").desc
  scope :closed, where("buyer_status = ?", 'Closed')
  scope :alive, where("buyer_status != ?", 'Removed')
  
  scope :with_bids, where('bids_count > 0')
  scope :without_bids, where('bids_count < 1')

	def add_line_items_from_cart(cart)
		cart.cart_items.each do |item|
			li = LineItem.from_cart_item(item)
			line_items << li 
		end
	end 

	def create_new_city
	  create_city(:name => new_city) unless new_city.blank?
	end

	def new_city_blank
	  new_city.blank?
	end

	def vehicle
	  "#{year_model} #{car_brand.name} #{car_model.name} #{car_variant.name if car_variant}" 
	end
	
	def brand
    car_brand.name.downcase
	end
	
	def update_associated_status(status)
    if status == "For Decision"
      line_items.each do |item|
        item.update_attribute(:status, status) if item.bids 
        item.update_attribute(:status, "No Bids") if item.bids.blank?
      end
    else
      line_items.update_all(:status => status)
    end
    bids.update_all(:status => status) if bids
	end

	def update_status
	  bid_count = self.bids.collect(&:line_item_id).uniq.count
	  unless self.orders.blank?
      if bid_count == self.order_items.count || bid_count == self.orders.count
        self.update_attribute(:buyer_status, "Ordered-All")
      elsif bid_count == self.order_items.count + self.line_items.status_eq('Declined').count
        self.update_attribute(:buyer_status, "Ordered-Declined")
      else
        self.update_attribute(:buyer_status, "Ordered-IP")
      end
	  else
  	  declined_count = self.line_items.status_eq('Declined').count
      if bid_count == declined_count
        self.update_attribute(:buyer_status, "Declined-All")
      else
        self.update_attribute(:buyer_status, "Declined-IP")
      end
	  end
	end
	
  def self.search(search)  
    if search  
      # where('plate_no LIKE ? ', "%#{search}%") 
      plate_no_like_any(search) 
    else  
      scoped  
    end  
  end  
  
  def bids_count
	  bids.count
	end
	
end
