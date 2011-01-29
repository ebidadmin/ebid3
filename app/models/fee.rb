class Fee < ActiveRecord::Base
  belongs_to :buyer_company, :class_name => "Company"
  belongs_to :seller_company, :class_name => "Company"
  belongs_to :buyer, :class_name => "User"
  belongs_to :seller, :class_name => "User"
  belongs_to :entry
  belongs_to :line_item
  belongs_to :order
  belongs_to :bid
  
  scope :declined, where(:fee_type => ['Declined', 'Expired'], :buyer_company_id => 2)
  scope :inclusions, includes([:entry => [:car_brand, :car_model, :car_variant, :user]], [:line_item => :car_part])
end
