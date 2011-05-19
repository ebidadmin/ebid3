class AddBidSpeedToBids < ActiveRecord::Migration
  def self.up
    add_column :bids, :bid_speed, :integer
    for bid in Bid.all
      bid.update_attribute(:bid_speed, (bid.created_at - bid.line_item.created_at).to_i)
    end
  end

  def self.down
    remove_column :bids, :bid_speed
  end
end
