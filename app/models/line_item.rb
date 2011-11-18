class LineItem < ActiveRecord::Base
  attr_accessor :diffs_cnt
  
  belongs_to :entry, :counter_cache => true
  belongs_to :car_part
  
  has_many :bids, :dependent => :destroy
  has_one :order_item
  has_one :order, :through => :order_item
  has_one :fee
  has_many :diffs
  
  scope :desc, order('id desc')
  scope :fresh, where(:status => ['New', 'Edited'])
  scope :online, where(:status => ['Online', 'Relisted', 'Additional'])
  scope :relistable, where(:status => 'No Bids')
  scope :cancelled, where('line_items.status LIKE ?', "%Cancelled%")
  scope :not_cancelled, where('bids.status NOT LIKE AND NOT LIKE ?', "%Cancelled%") 
  scope :with_bids, where('line_items.bids_count > 0')
  scope :two_and_up, where('line_items.bids_count > 2')
  scope :without_bids, where('line_items.bids_count < 1')

  scope :inclusions, includes([:entry => [:car_brand, :car_model, :car_variant, :user, :city, :term]], :car_part, [:bids => :user])
  scope :inclusions2, includes([:entry => [:car_brand, :car_model, :car_variant, :user, [:bids => :user]]], :car_part ) # Used in Admin#Bids
  
  scope :metered, where('line_items.created_at >= ?', '2011-04-16')
  scope :ftm, where('line_items.created_at >= ?', Time.now.beginning_of_month)

	def part_name
	  self.car_part.name
	end
	
	def self.from_cart_item(cart_item)
		li = self.new
		li.quantity = cart_item.quantity
		li.car_part_id = cart_item.car_part_id
		li.part_no = cart_item.part_no
		li 
	end 
	
	def update_for_decision
	  if bids.present?
      update_attribute(:status, "For-Decision") unless order.present?
      if bids.orig.present?
        low_orig = bids.orig.not_cancelled.last
        if low_orig
        low_orig.update_attribute(:status, "For-Decision") unless order.present?
        other_orig = bids.orig.not_cancelled.where("id != ?", low_orig)
        other_orig.update_all(:status => "Lose") 
        end
      end
      if bids.rep.present?
        low_rep = bids.rep.not_cancelled.last
        if low_rep
        low_rep.update_attribute(:status, "For-Decision") unless order.present?
        other_rep = bids.rep.not_cancelled.where("id != ?", low_rep)
        other_rep.update_all(:status => "Lose") 
        end
      end
      if bids.surp.present?
        low_surp = bids.surp.not_cancelled.last
        if low_surp
        low_surp.update_attribute(:status, "For-Decision") unless order.present?
        other_surp = bids.surp.not_cancelled.where("id != ?", low_surp)
        other_surp.update_all(:status => "Lose") 
        end
      end
	  else
      update_attribute(:status, "No Bids") 
	  end 
	end
	
	def update_for_decline
    if bids.present? #WITH BIDS
      update_attribute(:status, "Expired")
      lowest_bid = bids.where(:status => 'For-Decision').order(:amount, :bid_speed).first
      if lowest_bid.present?
        lowest_bid.update_attributes(:status => "Declined", :declined => Time.now, :expired => Time.now)  # lowest bid gets decline fee, others are dropped
        if bids.orig.present?
          low_orig = bids.orig.not_cancelled.where('bids.bid_type != ?', lowest_bid.bid_type).last
          if low_orig.present?
          low_orig.update_attribute(:status, "Dropped") 
          other_orig = bids.orig.not_cancelled.where("id != ?", low_orig)
          other_orig.update_all(:status => "Lose") 
          end
        end
        if bids.rep.present?
          low_rep = bids.rep.not_cancelled.where('bids.bid_type != ?', lowest_bid.bid_type).last
          if low_rep.present?
          low_rep.update_attribute(:status, "Dropped") 
          other_rep = bids.rep.not_cancelled.where("id != ?", low_rep)
          other_rep.update_all(:status => "Lose") 
          end
        end
        if bids.surp.present?
          low_surp = bids.surp.not_cancelled.where('bids.bid_type != ?', lowest_bid.bid_type).last
          if low_surp.present?
          low_surp.update_attribute(:status, "Dropped") 
          other_surp = bids.surp.not_cancelled.where("id != ?", low_surp)
          other_surp.update_all(:status => "Lose") 
          end
        end
      end
      # fee.blank? ? Fee.compute(lowest_bid, "Declined") : self.fee.update_attribute(:fee_type, "Expired") 
      Fee.compute(lowest_bid, "Declined") if fee.blank?
    else #WITHOUT BIDS
      update_attribute(:status, "No Bids")
    end
	end
	
	def fix_ordered
    # find bid with order, lowest for other bid types dropped, others lose
    ordered = bids.not_cancelled.with_order.first
    if ordered.present?
      if bids.orig.present?
        low_orig = bids.orig.not_cancelled.where('bids.bid_type != ?', ordered.bid_type).last
        if low_orig.present?
          low_orig.update_attribute(:status, "Dropped") 
          other_orig = bids.orig.not_cancelled.where('bids.bid_type != ?', ordered.bid_type).where("id != ?", low_orig)
          other_orig.update_all(:status => "Lose") if other_orig.present?
        end
      end
      if bids.rep.present?
        low_rep = bids.rep.not_cancelled.where('bids.bid_type != ?', ordered.bid_type).last
        if low_rep.present?
          low_rep.update_attribute(:status, "Dropped") 
          other_rep = bids.rep.not_cancelled.where('bids.bid_type != ?', ordered.bid_type).where("id != ?", low_rep)
          other_rep.update_all(:status => "Lose") if other_rep.present?
        end
      end
      if bids.surp.present?
        low_surp = bids.surp.not_cancelled.where('bids.bid_type != ?', ordered.bid_type).last
        if low_surp.present?
          low_surp.update_attribute(:status, "Dropped") 
          other_surp = bids.surp.not_cancelled.where('bids.bid_type != ?', ordered.bid_type).where("id != ?", low_surp)
          other_surp.update_all(:status => "Lose") if other_surp.present?
        end
      end
      others = bids.not_cancelled.where(:bid_type => ordered.bid_type).where("id != ?", ordered)
      others.update_all(:status => "Lose") if others
      ordered.update_attribute(:status, order.status)
      update_attribute(:status, order.status)
    end
	end
	
	def fix_declined
    # find bid with decline, lowest for other bid types dropped, others lose
    declined = bids.declined.first
    if declined.present?
      if bids.orig.present?
        low_orig = bids.orig.not_cancelled.where('bids.bid_type != ?', declined.bid_type).last
        if low_orig.present?
          low_orig.update_attribute(:status, "Dropped") 
          other_orig = bids.orig.not_cancelled.where('bids.bid_type != ?', declined.bid_type).where("id != ?", low_orig)
          other_orig.update_all(:status => "Lose") if other_orig.present?
        end
      end
      if bids.rep.present?
        low_rep = bids.rep.not_cancelled.where('bids.bid_type != ?', declined.bid_type).last
        if low_rep.present?
          low_rep.update_attribute(:status, "Dropped") 
          other_rep = bids.rep.not_cancelled.where('bids.bid_type != ?', declined.bid_type).where("id != ?", low_rep)
          other_rep.update_all(:status => "Lose") if other_rep.present?
        end
      end
      if bids.surp.present?
        low_surp = bids.surp.not_cancelled.where('bids.bid_type != ?', declined.bid_type).last
        if low_surp.present?
          low_surp.update_attribute(:status, "Dropped") 
          other_surp = bids.surp.not_cancelled.where('bids.bid_type != ?', declined.bid_type).where("id != ?", low_surp)
          other_surp.update_all(:status => "Lose") if other_surp.present?
        end
      end
      others = bids.not_cancelled.where(:bid_type => declined.bid_type).where("id != ?", declined)
      others.update_all(:status => "Lose") if others.present?
    end
	end
	
	def check_and_update_associated_relationships
    bids.each { |bid| bid.update_attributes(:quantity => quantity, :total => bid.amount * quantity) } if bids
    order_item.update_attributes(:quantity => quantity, :total => order_item.price * quantity)  if order_item
	end
	
	def last_bid(users, bid_type)
	  last_bid = bids.where(:user_id => users, :bid_type => bid_type).last
	end

	def high_bid(bid_type)
    bids.where(:bid_type => bid_type).not_cancelled.order('amount DESC').order('bid_speed DESC').first
	end
	
	def low_bid(bid_type)
    # self.bids.bid_type_eq(bid_type).status_does_not_equal('Ordered').descend_by_amount.last
    bids.where(:bid_type => bid_type).not_cancelled.order('amount DESC').order('bid_speed DESC').last
	end
	
	def last_diff(bid_type)
	  diffs.where(:bid_type => bid_type).last
	end

	def self.with_bids_pct
	  (with_bids.count.to_f/self.count.to_f) * 100
	end

	def self.two_and_up_pct
	  (two_and_up.count.to_f/self.count.to_f) * 100
	end
	
	def self.fastest
    # collecbids.order(:bid_speed).last.map { |bid| bid.speed }
	end
	
	def cancelled? # in entry#expire
	  status == "Cancelled by buyer" || status == "Cancelled by seller" || status == "Cancelled by admin"
	end
	
	def compute_lowest_bids # used in diff summary
	  unless bids.nil?
  	  bids.order(:amount).first.total 
	  else
	    0
    end
	end
	
  def self.search(search)  
    if search  
      finder = Entry.where('plate_no LIKE ? ', "%#{search}%") 
      where(:entry_id => finder)
    else  
      scoped  
    end  
  end  

  def self.since_eval(date)
    where('line_items.created_at >= ?', date)
  end

  def declined_or_expired? # in entry#expire
    status == "Declined" || status == "Expired"
  end
end
