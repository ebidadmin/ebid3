class CreateCities < ActiveRecord::Migration
  def self.up
    create_table :cities do |t|
      t.string :name
      t.timestamps
    end
    City.create(:name => 'Makati') 
    City.create(:name => 'Manila') 
    City.create(:name => 'Quezon City') 
    City.create(:name => 'Marikina') 
    City.create(:name => 'Mandaluyong') 
    City.create(:name => 'San Juan') 
    City.create(:name => 'Pasig') 
    City.create(:name => 'Pasay') 
    City.create(:name => 'Paranaque') 
    City.create(:name => 'Muntinlupa') 
    City.create(:name => 'Las Pinas') 
    City.create(:name => 'Caloocan')
  end

  def self.down
    drop_table :cities
  end
end
