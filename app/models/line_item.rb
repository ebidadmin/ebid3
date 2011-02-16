class LineItem < ActiveRecord::Base
  belongs_to :entry, :counter_cache => true
  belongs_to :car_part
  
  has_many :bids, :dependent => :destroy
  has_one :order_item
  has_one :order, :through => :order_item
  has_many :fees
  has_many :diffs
  
  scope :online, where("status IN ('Online', 'Relisted')")
  scope :with_bids, where('bids_count > 0')
  scope :two_and_up, where('bids_count > 2')
  scope :without_bids, where('bids_count < 1')

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
	
	def check_and_update_associated_relationships
    bids.each { |bid| bid.update_attributes(:quantity => quantity, :total => bid.amount * quantity) } if bids
    order_item.update_attributes(:quantity => quantity, :total => order_item.price * quantity)  if order_item
	end
	
	def last_bid(user, bid_type)
	  last_bid = bids.where(:user_id => user, :bid_type => bid_type).last
	end

	def high_bid(bid_type)
    bids.where(:bid_type => bid_type).order('amount').last
	end
	
	def low_bid(bid_type)
    # self.bids.bid_type_eq(bid_type).status_does_not_equal('Ordered').descend_by_amount.last
    bids.where(:bid_type => bid_type).order('amount').first
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
	
	def tat
	  ((bids.first.created_at - created_at)/86400).to_i
	end
  
end
