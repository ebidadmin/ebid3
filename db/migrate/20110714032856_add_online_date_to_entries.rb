class AddOnlineDateToEntries < ActiveRecord::Migration
  def self.up
    add_column :entries, :online, :datetime
    add_column :entries, :relisted, :datetime
    add_column :entries, :relist_count, :integer, :default => 0
    add_column :line_items, :relisted, :datetime
    change_column :entries, :bid_until, :datetime
    
    for entry in Entry.all
      if entry.bid_until.present?
        if entry.id == 1313
          entry.online = Time.now - 6.hours
          for bid in entry.bids
            bid.bid_speed = (bid.created_at - entry.online).to_i
            bid.save!
          end
        elsif entry.created_at >= "2011-07-11".to_datetime
          entry.online = entry.created_at + 5.minutes
          for bid in entry.bids
            bid.bid_speed = (bid.created_at - entry.online).to_i
            bid.save!
          end
        else 
          entry.online = entry.created_at + 5.minutes
        end
      end
      entry.save!
    end
  end

  def self.down
    change_column :entries, :bid_until, :date
    remove_column :line_items, :relisted
    remove_column :entries, :relist_count
    remove_column :entries, :relisted
    remove_column :entries, :online
  end
end