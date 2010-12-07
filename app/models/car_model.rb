class CarModel < ActiveRecord::Base
  attr_accessible :car_brand_id, :name
  belongs_to :car_brand
  has_many :car_variants
  has_many :entries
  
  validates_presence_of :name, :message => "Oops! You forgot the car model's name!"
end
