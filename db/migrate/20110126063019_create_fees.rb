class CreateFees < ActiveRecord::Migration
  def self.up
    create_table :fees do |t|
      t.integer :buyer_company_id
      t.integer :buyer_id
      t.integer :seller_company_id
      t.integer :seller_id
      t.integer :entry_id
      t.integer :line_item_id
      t.integer :order_id
      t.integer :bid_id
      t.decimal :bid_total, :precision => 10, :scale => 2
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
    
    bids = Bid.where('fee IS NOT NULL')
    for bid in bids
      f = Fee.new
      f.buyer_company_id = bid.entry.user.company.id
      f.buyer_id = bid.entry.user_id
      f.seller_company_id = bid.user.company.id
      f.seller_id = bid.user_id
      f.entry_id = bid.entry_id
      f.line_item_id = bid.line_item_id
      f.bid_id = bid.id
      f.bid_total = bid.total
      f.fee = bid.fee
      if bid.declined && bid.expired
        f.fee_type = 'Expired'
        f.created_at = bid.expired
        f.split_amount = f.fee/2
      elsif bid.declined
        f.fee_type = 'Declined'
        f.created_at = bid.declined
        f.split_amount = f.fee/2
      else
        f.order_id = bid.order_id
        f.fee_type = 'Ordered'
        f.created_at = bid.paid
      end 
      f.save
    end
  end

  def self.down
    remove_index :fees, :bid_id
    remove_index :fees, :column_name
    remove_index :fees, :column_name
    remove_index :fees, :entry_id
    remove_index :fees, :seller_id
    remove_index :fees, :buyer_id
    remove_index :fees, :seller_company_id
    remove_index :fees, :buyer_company_id
    drop_table :fees
  end
end