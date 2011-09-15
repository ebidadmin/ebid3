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
  belongs_to :canvass_company

  validates :canvass_amount, :numericality => {:greater_than => 0}, :presence => true
  validates :canvass_company, :presence => true
  
  def self.populate(entry, line_item, diff_type, amount, canvass_company)
    diff = Diff.new
		diff.buyer_company_id = entry.company_id
		diff.buyer_id = entry.user_id
		diff.entry_id = entry.id
		diff.line_item_id = line_item.id
    diff.bid_type = diff_type
		diff.canvass_amount = amount
		diff.canvass_total = amount * line_item.quantity.to_i
    diff.canvass_company_id = canvass_company
    # existing_bid = Bid.find_by_line_item_id_and_bid_type_and_amount(@line_item.id, diff[0], diff[1]) #Bid.find_by_line_item_id_and_bid_type(line_item, diff[0])
        existing_bid = Bid.where(:line_item_id => line_item.id, :bid_type => diff_type).order(:amount).first
    if existing_bid.present? 
          diff.seller_company_id = existing_bid.user.company.id
          diff.seller_id = existing_bid.user_id
          diff.bid_id = existing_bid.id 
          diff.amount = existing_bid.amount 
          diff.quantity = existing_bid.quantity
          diff.total = existing_bid.total
          diff.diff = diff.total - diff.canvass_total
    end
    diff.save!
  end
end
