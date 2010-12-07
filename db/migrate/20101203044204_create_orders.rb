class CreateOrders < ActiveRecord::Migration
  def self.up
    create_table :orders do |t|
      t.integer :user_id
      t.integer :company_id
      t.integer :entry_id
      t.string :deliver_to, :default => ""
      t.string :address1, :default => ""
      t.string :address2, :default => ""
      t.string :contact_person, :default => ""
      t.string :phone, :default => ""
      t.string :fax, :default => ""
      t.text :instructions, :default => ""
      t.string :status, :null => false, :default => "PO Released"
      t.string :buyer_ip, :default => ""
      t.integer :order_items_count, :null => false, :default => 0
      t.decimal :order_total, :precision => 10, :scale => 2, :null => false, :default => 0.0
      t.integer :seller_id
      t.boolean :seller_confirmation, :null => false, :default => 0
      t.timestamps
      t.date :delivered
      t.date :pay_until
      t.date :paid
      t.integer :ratings_count, :null => false, :default => 0
    end
    add_index :orders, :user_id
    add_index :orders, :company_id
    add_index :orders, :entry_id
    add_index :orders, :seller_id
  end

  def self.down
    remove_index :orders, :seller_id
    remove_index :orders, :entry_id
    remove_index :orders, :company_id
    remove_index :orders, :user_id
    drop_table :orders
  end
end