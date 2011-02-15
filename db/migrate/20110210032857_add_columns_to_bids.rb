class AddColumsToBids < ActiveRecord::Migration
  def self.up
    remove_column :bids, :fee
    remove_column :bids, :remitted
    add_column :bids, :car_brand_id, :integer
    for bid in Bid.all
      bid.update_attribute(:car_brand_id, bid.entry.car_brand.id)
    end
    add_column :entries, :company_id, :integer
    for entry in Entry.all
      entry.update_attributes(:company_id => entry.user.profile.company.id)
    end
    add_index :bids, :car_brand_id
    add_index :entries, :company_id
  end

  def self.down
    remove_index :entries, :company_id
    remove_index :bids, :car_brand_id
    remove_column :entries, :company_id
    remove_column :bids, :car_brand_id
  end
end