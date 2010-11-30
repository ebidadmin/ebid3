class CreateCarVariants < ActiveRecord::Migration
  def self.up
    create_table :car_variants do |t|
      t.integer :car_brand_id
      t.integer :car_model_id
      t.string :name
      t.string :start_year
      t.string :end_year
      t.timestamps
    end
    add_index :car_variants, :car_brand_id
    add_index :car_variants, :car_model_id
  end

  def self.down
    remove_index :car_variants, :car_model_id
    remove_index :car_variants, :car_brand_id
    drop_table :car_variants
  end
end