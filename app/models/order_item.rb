class OrderItem < ActiveRecord::Base

  belongs_to :entry
  belongs_to :line_item
  belongs_to :bid
  belongs_to :order, :counter_cache => true
  has_one :car_part, :through => :line_item
  
  delegate :part_name, :to => :line_item
  scope :metered, where('order_items.created_at >= ?', '2011-04-16')
  scope :ftm, where('order_items.created_at >= ?', Time.now.beginning_of_month)
  
  def self.populate(order, user_bids)
    user_bids.each do |bid|
      order_item = OrderItem.new(
        :line_item_id => bid.line_item_id,
        :quantity => bid.quantity,
        :price => bid.amount,
        :total => bid.total,
        :source => bid.bid_type,
        :bid_id => bid.id
      )
      order.order_items << order_item
    end
  end

end
