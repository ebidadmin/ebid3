class Cart < ActiveRecord::Base
  has_many :cart_items, :dependent => :destroy
  has_many :car_parts, :through => :cart_items

  def add(car_part)
    items = cart_items.where("car_part_id = ?", car_part)
    
    if items.size < 1
      ci = cart_items.create(:car_part_id => car_part,
        :quantity => 1,
        :part_no => "")
    else
      ci = items.first
      ci.update_attribute(:quantity, ci.quantity + 1)
    end
    ci
  end
  
  def remove(car_part)
    ci = cart_items.find_by_car_part_id(car_part)
    
    if ci.quantity > 1
      ci.update_attribute(:quantity, ci.quantity - 1)
    else
      CartItem.destroy(ci.id)
    end
    ci
  end
  
  def update(car_part)
    ci = cart_items.where("car_part_id = ?", car_part)
    ci.update_attributes(:quantity => ci.quantity, :part_no => ci.part_no)
  end
  
  def total
		cart_items.collect(&:quantity).sum 
	end 
end
