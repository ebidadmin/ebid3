class CreateCarOrigins < ActiveRecord::Migration
  def self.up
    create_table :car_origins do |t|
      t.string :name
    end
    # CarOrigin.create(:name => 'Japanese')
    # CarOrigin.create(:name => 'American')
    # CarOrigin.create(:name => 'European')
    # CarOrigin.create(:name => 'Asian')
  end

  def self.down
    drop_table :car_origins
  end
end
