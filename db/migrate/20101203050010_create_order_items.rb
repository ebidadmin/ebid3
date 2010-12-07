class CreateOrderItems < ActiveRecord::Migration
  def self.up
    create_table :order_items do |t|
      t.integer :line_item_id
      t.integer :order_id
      t.integer :quantity
      t.decimal :price, :precision => 10, :scale => 2, :null => false, :default => 0.0
      t.decimal :total, :precision => 10, :scale => 2, :null => false, :default => 0.0
      t.string :source
      t.timestamps
    end
    add_index :order_items, :line_item_id
    add_index :order_items, :order_id
  end

  def self.down
    remove_index :order_items, :order_id
    remove_index :order_items, :line_item_id
    drop_table :order_items
  end
end