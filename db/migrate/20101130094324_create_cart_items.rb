class CreateCartItems < ActiveRecord::Migration
  def self.up
    create_table :cart_items do |t|
      t.integer :cart_id
      t.integer :car_part_id
      t.integer :quantity
      t.string :part_no
      t.datetime :created_at
      t.timestamps
    end
    add_index :cart_items, :cart_id
    add_index :cart_items, :car_part_id
  end

  def self.down
    remove_index :cart_items, :car_part_id
    remove_index :cart_items, :cart_id
    drop_table :cart_items
  end
end