class CreateCarBrands < ActiveRecord::Migration
  def self.up
    create_table :car_brands do |t|
      t.integer :car_origin_id
      t.string :name
      t.timestamps
    end
    add_index :car_brands, :car_origin_id
  end

  def self.down
    remove_index :car_brands, :car_origin_id
    drop_table :car_brands
  end
end