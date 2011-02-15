class CreateDiffs < ActiveRecord::Migration
  def self.up
    create_table :diffs do |t|
      t.integer :buyer_company_id
      t.integer :buyer_id
      t.integer :seller_company_id
      t.integer :seller_id
      t.integer :entry_id
      t.integer :line_item_id
      t.integer :bid_id
      t.decimal :amount, :precision => 10, :scale => 2
      t.integer :quantity, :null => false, :default => 1
      t.decimal :total, :precision => 10, :scale => 2
      t.string :bid_type
      t.decimal :canvass_amount, :precision => 10, :scale => 2
      t.decimal :canvass_total, :precision => 10, :scale => 2
      t.decimal :diff, :precision => 10, :scale => 2
      t.integer :canvass_company_id
      t.timestamps
    end
    add_index :diffs, :buyer_company_id
    add_index :diffs, :seller_company_id
    add_index :diffs, :buyer_id
    add_index :diffs, :seller_id
    add_index :diffs, :entry_id
    add_index :diffs, :line_item_id
    add_index :diffs, :bid_id
    add_index :diffs, :canvass_company_id
  end

  def self.down
    remove_index :diffs, :canvass_company_id
    remove_index :diffs, :bid_id
    remove_index :diffs, :line_item_id
    remove_index :diffs, :entry_id
    remove_index :diffs, :seller_id
    remove_index :diffs, :buyer_id
    remove_index :diffs, :seller_company_id
    remove_index :diffs, :buyer_company_id
    drop_table :diffs
  end
end
