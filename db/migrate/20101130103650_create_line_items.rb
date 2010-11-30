class CreateLineItems < ActiveRecord::Migration
  def self.up
    create_table :line_items do |t|
      t.integer :entry_id
      t.integer :car_part_id
      t.string :part_no, :default => ''
      t.integer :quantity, :null => false, :default => 1
      t.timestamps
      t.string :status, :default => 'New'
      t.integer :bids_count, :null => false, :default => 0
    end
    add_index :line_items, :entry_id
    add_index :line_items, :car_part_id
  end

  def self.down
    remove_index :line_items, :car_part_id
    remove_index :line_items, :entry_id
    drop_table :line_items
  end
end