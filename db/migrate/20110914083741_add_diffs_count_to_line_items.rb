class AddDiffsCountToLineItems < ActiveRecord::Migration
  def self.up
    add_column :line_items, :diffs_cnt, :integer
  end
  
  for item in LineItem.where("created_at > ?", "2010-11-01")
    item.diffs_cnt = item.diffs.count
    item.save!
  end

  def self.down
    remove_column :line_items, :diffs_cnt
  end
end