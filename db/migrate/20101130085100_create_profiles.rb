class CreateProfiles < ActiveRecord::Migration
  def self.up
    create_table :profiles do |t|
      t.integer :user_id
      t.integer :company_id
      t.string :first_name
      t.string :last_name
      t.integer :rank_id
      t.string :phone
      t.string :fax
      t.date :birthdate

      t.timestamps
    end
    add_index :profiles, :user_id
    add_index :profiles, :company_id
    
    # Profile.create!(:user_id => 1,
    #                   :company_id => 1,
    #                   :first_name => 'Chris',
    #                   :last_name => 'Marquez',
    #                   :phone => '892-5835',
    #                   :fax => "817-1979", 
    #                   :rank_id => 1,
    #                   :birthdate => Date.today)
    # Profile.create!(:user_id => 2,
    #                   :company_id => 1,
    #                   :first_name => 'Efren',
    #                   :last_name => 'Magtibay',
    #                   :phone => '892-5835',
    #                   :fax => "817-1979", 
    #                   :rank_id => 1,
    #                   :birthdate => Date.today)
  end

  def self.down
    drop_table :profiles
  end
end
