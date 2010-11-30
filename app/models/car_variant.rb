class CarVariant < ActiveRecord::Base
  attr_accessible :car_brand_id, :car_model_id, :name, :start_year, :end_year
end
