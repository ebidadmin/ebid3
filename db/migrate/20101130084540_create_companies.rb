class CreateCompanies < ActiveRecord::Migration
  def self.up
    create_table :companies do |t|
      t.string :name
      t.string :address1
      t.string :address2
      t.string :zip_code
      t.integer :city_id
      t.string :approver
      t.string :approver_position
      t.timestamps
      t.integer :primary_role
    end
    Company.create!(:name => 'e-Bid, Inc.', 
                    :address1 => '2/F Corinthian Plaza', 
                    :address2 => '121 Paseo de Roxas',
                    :zip_code => '1226',
                    :city_id => 1,
                    :approver => 'Ted Toribio',
                    :approver_position => 'President')
  end

  def self.down
    drop_table :companies
  end
end
