class CreateEntries < ActiveRecord::Migration
  def self.up
    create_table :entries do |t|
      t.integer :user_id
      t.string :ref_no
      t.integer :year_model, :limit => 4, :default => Date.today.year
      t.integer :car_brand_id, :default => 0
      t.integer :car_model_id, :default => 0
      t.integer :car_variant_id, :default => 0
      t.string :plate_no
      t.string :serial_no
      t.string :motor_no
      t.date :date_of_loss
      t.integer :city_id
      t.integer :term_id
      t.timestamps
      t.date :bid_until
      t.string :buyer_status, :default => 'New'
      t.integer :photos_count, :null => false, :default => 0
      t.boolean :additional_flag, :default => false
      t.date :expired
      t.boolean :chargeable_expiry, :default => false
    end
    add_index :entries, :user_id
    add_index :entries, :car_brand_id
    add_index :entries, :car_model_id
    add_index :entries, :car_variant_id
    add_index :entries, :city_id
    add_index :entries, :term_id
  end

  def self.down
    remove_index :entries, :term_id
    remove_index :entries, :city_id
    remove_index :entries, :car_variant_id
    remove_index :entries, :car_model_id
    remove_index :entries, :car_brand_id
    remove_index :entries, :user_id
    drop_table :entries
  end
end