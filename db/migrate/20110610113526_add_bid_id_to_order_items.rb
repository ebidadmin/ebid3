class AddBidIdToOrderItems < ActiveRecord::Migration
  def self.up
    add_column :order_items, :bid_id, :integer
    
    for order_item in OrderItem.all
      bid = Bid.find_by_line_item_id_and_total(order_item.line_item_id, order_item.total)
      order_item.bid_id = bid.id unless bid.blank?
      order_item.save!
    end
  end

  def self.down
    remove_column :order_items, :bid_id
  end
end
