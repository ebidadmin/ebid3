class CreateBids < ActiveRecord::Migration
  def self.up
    create_table :bids do |t|
      t.integer :user_id
      t.integer :entry_id
      t.integer :line_item_id
      t.decimal :amount, :precision => 10, :scale => 2
      t.integer :quantity, :null => false, :default => 1
      t.decimal :total, :precision => 10, :scale => 2
      t.string :bid_type
      t.boolean :lot, :default => false
      t.string :status, :null => false, :default => "Submitted"
      t.timestamps
      t.date :ordered
      t.integer :order_id
      t.date :delivered
      t.date :paid
      t.decimal :fee, :precision => 10, :scale => 2
      t.date :remitted
      t.date :declined
      t.date :expired
    end
    add_index :bids, :user_id
    add_index :bids, :entry_id
    add_index :bids, :line_item_id
    add_index :bids, :order_id
  end

  def self.down
    remove_index :bids, :order_id
    remove_index :bids, :line_item_id
    remove_index :bids, :entry_id
    remove_index :bids, :user_id
    drop_table :bids
  end
end