class Company < ActiveRecord::Base
  attr_accessible :name, :address1, :address2, :zip_code, :city_id, :approver, :approver_position
end
