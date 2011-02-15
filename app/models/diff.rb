class Diff < ActiveRecord::Base
  attr_accessible :buyer_company_id, :buyer_id, :seller_company_id, :seller_id, :entry_id, :line_item_id, :amount, :quantity, :total,
    :bid_type, :canvass_amount, :canvass_total, :diff, :canvass_company_id
     
  belongs_to :buyer_company, :class_name => "Company"
  belongs_to :seller_company, :class_name => "Company"
  belongs_to :buyer, :class_name => "User"
  belongs_to :seller, :class_name => "User"
  belongs_to :entry
  belongs_to :line_item
  belongs_to :bid
  belongs_to :canvass_company, :class_name => "Company"

  validates :canvass_amount, :numericality => {:greater_than => 0}, :presence => true
  validates :canvass_company, :presence => true
end
