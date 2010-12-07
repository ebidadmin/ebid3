class CartItem < ActiveRecord::Base
  belongs_to :car_part
  belongs_to :cart
  
  def part_name
		car_part.name
	end 
end
