class Entry < ActiveRecord::Base
  attr_accessible :user_id, :ref_no, :year_model, :car_brand_id, :car_model_id, :car_variant_id, :plate_no, :serial_no, :motor_no, :date_of_loss, :city_id, :term_id, :bid_until, :buyer_status, :photos_count, :additional_flag, :expired, :chargeable_expiry
end
