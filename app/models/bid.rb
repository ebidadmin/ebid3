class Bid < ActiveRecord::Base
  attr_accessible :user_id, :entry_id, :line_item_id, :amount, :quantity, :total,
    :bid_type, :status, :ordered, :order_id, :delivered, :paid, :fee, :remitted, :declined, :expired
     
  belongs_to :user, :counter_cache => true
  belongs_to :entry, :counter_cache => true
  belongs_to :line_item, :counter_cache => true
  belongs_to :car_part
  belongs_to :order

  validates :amount, :numericality => true, :presence => true
  
  scope :desc, order('id DESC')
  scope :bt, order('bid_type')
  scope :declined, where('declined != ?', '').order('declined DESC')

  def decline_process
    update_attributes(:status => "Declined", :ordered => nil, :order_id => nil, :delivered => nil, :fee => total * 0.0025, :declined => Date.today)
    update_unselected_bids(line_item_id)
  end

  def update_unselected_bids(line_item)
    all_bids_for_item = Bid.where(:line_item_id => line_item)
    bids_by_same_seller = all_bids_for_item.where("user_id = ? AND id != ?", self.user_id, self.id)
    bids_by_same_seller.update_all(:status => "Dropped", :ordered => nil, :order_id => nil, :delivered => nil, :paid => nil, :fee => nil, :declined => nil)
    bids_by_other_sellers = all_bids_for_item.where("user_id != ?", self.user_id)
    bids_by_other_sellers.update_all(:status => "Lose", :ordered => nil, :order_id => nil, :delivered => nil, :paid => nil, :fee => nil, :declined => nil)
  end
  
  def self.search(search)  
    if search  
      finder = Entry.where('plate_no LIKE ? ', "%#{search}%") 
      where(:entry_id => finder)
    else  
      scoped  
    end  
  end  
  
end
