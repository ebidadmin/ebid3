class CarBrand < ActiveRecord::Base
  attr_accessible :car_origin_id, :name


  belongs_to :car_origin
  has_many :car_models
  has_many :entries
  has_many :bids
  
  validates_presence_of :name
  
  def origin
    car_origin.order('id')
  end
end
