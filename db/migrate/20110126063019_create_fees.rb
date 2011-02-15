class CreateFees < ActiveRecord::Migration
  def self.up
    create_table :fees, :force => true do |t|
      t.integer :buyer_company_id
      t.integer :buyer_id
      t.integer :seller_company_id
      t.integer :seller_id
      t.integer :entry_id
      t.integer :line_item_id
      t.integer :order_id
      t.integer :bid_id
      t.decimal :bid_total, :precision => 10, :scale => 2
      t.string :bid_type
      t.decimal :fee, :precision => 10, :scale => 2
      t.string :fee_type
      t.date :created_at
      t.date :remitted
      t.decimal :split_amount, :precision => 10, :scale => 2
      t.date :split_date
    end
    
    add_index :fees, :buyer_company_id
    add_index :fees, :seller_company_id
    add_index :fees, :buyer_id
    add_index :fees, :seller_id
    add_index :fees, :entry_id
    add_index :fees, :line_item_id
    add_index :fees, :order_id
    add_index :fees, :bid_id
    
  end

  def self.down
    remove_index :fees, :bid_id
    remove_index :fees, :order_id
    remove_index :fees, :line_item_id
    remove_index :fees, :entry_id
    remove_index :fees, :seller_id
    remove_index :fees, :buyer_id
    remove_index :fees, :seller_company_id
    remove_index :fees, :buyer_company_id
    drop_table :fees
  end
end