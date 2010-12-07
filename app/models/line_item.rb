class LineItem < ActiveRecord::Base
  belongs_to :entry, :counter_cache => true
  belongs_to :car_part
  
  has_many :bids, :dependent => :destroy
  has_one :order_item
  has_one :order, :through => :order_item

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

end
