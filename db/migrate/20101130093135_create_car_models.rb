class CreateCarModels < ActiveRecord::Migration
  def self.up
    create_table :car_models do |t|
      t.integer :car_brand_id
      t.string :name
      t.timestamps
    end
    add_index :car_models, :car_brand_id
  end

  def self.down
    remove_index :car_models, :car_brand_id
    drop_table :car_models
  end
end