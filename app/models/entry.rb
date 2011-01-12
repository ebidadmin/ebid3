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
  scope :desc2, order('bid_until DESC')
  scope :asc, order('bid_until')
  scope :five, limit(5)

  scope :current, where(:expired => nil)
  scope :expired, where('expired IS NOT NULL')

  scope :pending, where("buyer_status IN ('New', 'Edited')")
  scope :online, where("buyer_status = ?", 'Online')
  scope :results, where("buyer_status IN ('For-Decision', 'Ordered-IP', 'Declined-IP')")
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
    item_count = bids.collect(&:line_item_id).uniq.count
	  unless orders.blank?
      if item_count == order_items.count || item_count == orders.count
        update_attribute(:buyer_status, "Ordered-All")
      elsif item_count == order_items.count + line_items.where("status IN  ('Declined', 'Expired')").count
        update_attribute(:buyer_status, "Ordered-Declined")
      else
        update_attribute(:buyer_status, "Ordered-IP")
      end
	  else
  	  declined_count = line_items.where("status IN  ('Declined', 'Expired')").count
      if item_count == declined_count
        update_attribute(:buyer_status, "Declined-All")
      else
        update_attribute(:buyer_status, "Declined-IP")
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
	
	def expire
    if buyer_status == "Online" && Date.today > bid_until #&& expired.nil?
      update_attribute(:expired, Date.today)
      line_items.each do |line_item|
        if line_item.bids.exists?
          line_item.update_attribute(:status, "Expired")
          bids.update_all(:status => 'Expired', :expired => Date.today)
        else
          line_item.update_attribute(:status, "No Bids")
        end
      end
    elsif (buyer_status == "For-Decision" || buyer_status == "Ordered-IP" || buyer_status == "Declined-IP")
      deadline = bid_until + 2.weeks unless bid_until.nil?
      if Date.today > deadline #&& expired_at.nil?
        update_attributes(:chargeable_expiry => true, :expired => Date.today)
        line_items.each do |line_item|
          unless (line_item.order_item || line_item.status == "Declined")
            itembids = line_item.bids #.where(:lot => nil)
            unless itembids.blank? #WITH BIDS
              lowest = itembids.order('amount').first
              others = itembids.where('id != ?', lowest)
              line_item.update_attribute(:status, "Expired")
              lowest.update_attributes(:status => "Declined", :fee => lowest.total * 0.0025, :declined => Date.today, :expired => Date.today) # lowest bid gets decline fee, others are dropped
              others.update_all(:status => 'Dropped', :fee => nil, :declined => nil, :expired => Date.today)
            else #WITHOUT BIDS
              line_item.update_attribute(:status, "No Bids")
            end
          end
        end
        update_status #unless orders.exists?
      end
    end
	end
end
