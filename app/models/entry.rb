class Entry < ActiveRecord::Base
  attr_accessible :user_id, :ref_no, :year_model, :car_brand_id, :car_model_id, :car_variant_id, :plate_no, :serial_no, :motor_no, :date_of_loss, 
    :city_id, :new_city, :term_id, :photos_attributes, :bid_until, :buyer_status, :chargeable_expiry, :expired, :online, :relisted
    
  attr_accessor :new_city
  before_save :create_new_city, :convert_numbers

  belongs_to :user, :counter_cache => true

  belongs_to :car_brand
  belongs_to :car_model
  belongs_to :car_variant
  belongs_to :city
  belongs_to :term
  belongs_to :company

  has_many :photos, :dependent => :destroy
  # accepts_nested_attributes_for :photos, :reject_if => lambda { |a| a.values.all?(&:blank?) }, :allow_destroy => true
  accepts_nested_attributes_for :photos, :allow_destroy => true, :reject_if => proc { |a| a['photo'].blank? }
  has_many :bids, :dependent => :destroy
  accepts_nested_attributes_for :bids

  has_many :line_items, :dependent => :destroy
  has_many :car_parts, :through => :line_items
  has_many :bids, :dependent => :destroy
  has_many :orders
  has_many :order_items, :through => :orders
  has_many :comments, :dependent => :destroy
  has_many :fees
  has_many :diffs
  has_many :messages, :dependent => :destroy

  validates_presence_of :year_model, :car_brand, :car_model, :plate_no, :serial_no, :motor_no, :term
  validates_presence_of :city, :if => :new_city_blank

  scope :desc, order('id desc')
  scope :desc2, order('bid_until desc', 'id desc')
  scope :asc, order('bid_until')
  scope :five, limit(5)

  scope :active, where('entries.bid_until >= ?', Date.today).desc2
  scope :unexpired, where(:expired => nil)
  scope :expired, where('expired IS NOT NULL')
  scope :metered, where('entries.created_at >= ?', '2011-04-16')
  scope :ftm, where('entries.created_at >= ?', Time.now.beginning_of_month)

  scope :pending, where(:buyer_status => ['New', 'Edited'])
  scope :online, where(:buyer_status => ['Online', 'Relisted'])
  scope :results, where(:buyer_status =>  ['For Decision', 'For-Decision', 'Ordered-IP', 'Declined-IP'])
  scope :ordered, where(:buyer_status =>  ['Ordered-All', 'Ordered-Declined', 'Closed'])
  scope :declined, where(:buyer_status =>  'Declined-All')
  scope :closed, where(:buyer_status => 'Closed')
  scope :discarded, where(:buyer_status =>  ['Removed', 'Expired'])
  scope :alive, where("buyer_status != ?", 'Removed')
  
  scope :with_bids, where("entries.bids_count > ?", 0)
  scope :without_bids, where('entries.bids_count < ?', 1)
  
  scope :latest, where('created_at >= ?', 5.days.ago)

  scope :inclusions, includes([:line_items => [:car_part]], :user, :car_brand, :car_model, :car_variant)
  scope :seller_inclusions, includes(:user, :car_brand, :car_model, :car_variant, :city, :term, :line_items, :photos, :bids, :orders)
  scope :admin_inclusions, includes(:user, :car_brand, :car_model, :car_variant, :city, :term, :photos, :bids, :orders, :messages)

	def add_line_items_from_cart(cart)
		cart.cart_items.each do |item|
			li = LineItem.from_cart_item(item)
			line_items << li 
		end
	end 

	def add_or_edit_line_items_from_cart(cart)
		cart.cart_items.each do |item|
      # existing_item = LineItem.where(:entry_id => self.id, :car_part_id => item.car_part_id)
		  existing_item = LineItem.find_by_entry_id_and_car_part_id(self.id, item.car_part_id)
		  unless existing_item.nil?
		    existing_item.update_attributes(:quantity => existing_item.quantity + item.quantity, :part_no => item.part_no)
        existing_item.check_and_update_associated_relationships
		  else
  			li = LineItem.from_cart_item(item)
  			line_items << li 
  		end
		end
	end 

	def create_new_city
	  unless new_city.blank?
	    existing_city = City.find_by_name(new_city)
	    if existing_city 
	      self.city_id = existing_city.id
      else
  	  create_city(:name => new_city.strip.titlecase) 
  	  end
  	end
	end

	def new_city_blank
	  new_city.blank?
	end
	
	def convert_numbers
	  self.plate_no.upcase!
	  self.motor_no.upcase!
	  self.serial_no.upcase!
	end

	def vehicle
	  "#{year_model} #{car_brand.name} #{car_model.name} #{car_variant.name if car_variant}" 
	end
	
	def brand
    car_brand.name.downcase
	end
	
	def buyer_company #used in diffs#index
	  user.company
	end

	def update_associated_status(status)
    if status == "For-Decision"
      line_items.online.each do |item|
        unless item.order_item || item.status == 'Declined' || item.status == 'Lose' || item.status == 'Dropped'
          item.update_attribute(:status, status) if item.bids 
          item.update_attribute(:status, "No Bids") if item.bids.blank?
          item.bids.update_all(:status => status) if bids
        end
      end
    elsif status == "Online"
      line_items.update_all(:status => status)
      bids.update_all(:status => 'Submitted') if bids
    else
      line_items.update_all(:status => status)
      bids.update_all(:status => status) if bids
    end
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
      # self.where('plate_no LIKE ? ', "%#{search}%") 
      plate_no_like_any(search) 
    else  
      scoped  
    end  
  end  
  
  def bids_count
	  bids.count
	end
	
	def expire
    if (buyer_status == "Online" || buyer_status == "Relisted") && Time.now > bid_until #&& expired.nil?
      update_attribute(:expired, Time.now)
      line_items.each do |line_item|
        if line_item.bids.exists?
          line_item.update_attribute(:status, "Expired")
          bids.update_all(:status => 'Expired', :expired => Time.now)
        else
          line_item.update_attribute(:status, "No Bids")
        end
      end
    elsif (buyer_status == "For Decision" || buyer_status == "For-Decision" || buyer_status == "Ordered-IP" || buyer_status == "Declined-IP")
      deadline = bid_until + 3.days unless bid_until.nil?
      if Time.now > deadline #&& expired_at.nil?
        update_attributes(:chargeable_expiry => true, :expired => Time.now)
        line_items.each do |line_item|
          unless (line_item.order_item || line_item.status == "Declined")
            itembids = line_item.bids #.where(:lot => nil)
            unless itembids.blank? #WITH BIDS
              lowest = itembids.order('amount').first
              others = itembids.where('id != ?', lowest)
              line_item.update_attribute(:status, "Expired")
              lowest.update_attributes(:status => "Declined", :declined => Time.now, :expired => Time.now) # lowest bid gets decline fee, others are dropped
              others.update_all(:status => 'Dropped', :declined => nil, :expired => Time.now)
              Fee.compute(lowest, "Declined")
            else #WITHOUT BIDS
              line_item.update_attribute(:status, "No Bids")
            end
          end
        end
        update_status #unless orders.exists?
      end
    end
	end

  def ready_for_reveal?
    if buyer_status == 'Relisted'
      Time.now > relisted + 180.minutes
    else         
      Time.now > online + 180.minutes
    end
  end

  def with_diffs
    diffs.count > 0
  end
end
