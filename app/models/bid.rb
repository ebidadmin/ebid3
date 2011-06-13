class Bid < ActiveRecord::Base
  attr_accessible :user_id, :entry_id, :line_item_id, :amount, :quantity, :total,
    :bid_type, :status, :ordered, :order_id, :delivered, :paid, :fee, :remitted, :declined, :expired, :bid_speed
     
  belongs_to :user, :counter_cache => true
  belongs_to :entry, :counter_cache => true
  belongs_to :line_item, :counter_cache => true
  belongs_to :car_brand
  belongs_to :car_part
  belongs_to :order

  has_one :fee
  has_one :order_item
  has_one :diff

  validates :amount, :numericality => {:greater_than => 0}, :presence => true
  
  scope :inclusions, includes([:entry => [:car_brand, :car_model, :car_variant, :user, :city, :term]], [:line_item => :car_part], :user)
  scope :desc, order('id DESC')
  scope :bt, order('bid_type')
  scope :declined, where(:status => 'Declined')#.order('declined DESC', 'entry_id DESC')
  
  scope :metered, where('bids.created_at >= ?', '2011-04-16')
  scope :ftm, where('bids.created_at >= ?', Time.now.beginning_of_month)
    
  def self.for_this_buyer(user)
    where(:entry_id => user.entries).count
  end
  
  def self.for_this_company(company)
    where(:entry_id => company.users.collect(&:entries)).count
  end
  
  def decline_process
    update_attributes(:status => "Declined", :ordered => nil, :order_id => nil, :delivered => nil, :declined => Date.today)
    update_unselected_bids(line_item_id)
    if fee.nil?
      Fee.compute(self, status)
    end
  end

  def update_unselected_bids(line_item)
    all_bids_for_item = Bid.where(:line_item_id => line_item)
    bids_by_same_seller = all_bids_for_item.where("user_id = ? AND id != ?", self.user_id, self.id)
    bids_by_same_seller.update_all(:status => "Dropped", :ordered => nil, :order_id => nil, :delivered => nil, :paid => nil, :declined => nil)
    bids_by_other_sellers = all_bids_for_item.where("user_id != ?", self.user_id)
    bids_by_other_sellers.update_all(:status => "Lose", :ordered => nil, :order_id => nil, :delivered => nil, :paid => nil, :declined => nil)
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
