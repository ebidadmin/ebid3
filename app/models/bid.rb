class Bid < ActiveRecord::Base
  attr_accessible :user_id, :entry_id, :line_item_id, :amount, :quantity, :total,
    :bid_type, :status, :ordered, :order_id, :delivered, :paid, :declined, :expired, :bid_speed
     
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
  scope :online, where(:status => ['Submitted', 'Updated'])
  scope :declined, where(:status => 'Declined')#.order('declined DESC', 'entry_id DESC')
  scope :cancelled, where('bids.status LIKE ?', "%Cancelled%") # used in Orders#Show
  scope :not_cancelled, where('bids.status NOT LIKE ?', "%Cancelled%") # used in Orders#Show
  
  scope :orig, where(:bid_type => 'original').order('amount DESC').order('bid_speed DESC')
  scope :rep, where(:bid_type => 'replacement').order('amount DESC').order('bid_speed DESC')
  scope :surp, where(:bid_type => 'surplus').order('amount DESC').order('bid_speed DESC')
  
  scope :with_order, order_id_not_null
  
  scope :metered, where('bids.created_at >= ?', '2011-04-16'.to_datetime)
  scope :ftm, where('bids.created_at >= ?', Time.now.beginning_of_month)
  
  def self.search(search)  
    if search  
      finder = Entry.where('plate_no LIKE ? ', "%#{search}%") 
      where(:entry_id => finder)
    else  
      scoped  
    end  
  end  
  
  def self.populate(user, entry, line_item, amount, type)
    nb = user.bids.build
		nb.entry_id = entry.id
		nb.line_item_id = line_item.id
		nb.amount = amount
		nb.quantity = line_item.quantity
		nb.total = amount.to_f * line_item.quantity.to_i
    nb.bid_type = type
    nb.car_brand_id = entry.car_brand_id
    nb.bid_speed = nb.compute_bid_speed  
    nb  
  end  
  
  def self.for_this_buyer(user)
    where(:entry_id => user.entries).count
  end
  
  def self.for_this_company(company)
    where(:entry_id => company.users.collect(&:entries)).count
  end
  
  def decline_process
    update_attributes(:status => "Declined", :ordered => nil, :order_id => nil, :delivered => nil, :declined => Date.today)
    update_unselected_bids2(line_item_id) 
    Fee.compute(self, status) if fee.nil?
  end
  
  def cancel_process(msg_type)
    update_attribute(:status, "Cancelled by #{msg_type}")
    line_item.update_attribute(:status, "Cancelled by #{msg_type}")
    order_item.destroy
  end

  def update_unselected_bids(line_item)
    all_bids_for_item = Bid.where(:line_item_id => line_item)
    bids_by_same_seller = all_bids_for_item.where("user_id = ? AND id != ?", self.user_id, self.id).not_cancelled
    bids_by_same_seller.update_all(:status => "Dropped", :ordered => nil, :order_id => nil, :delivered => nil, :paid => nil, :declined => nil)
    bids_by_other_sellers = all_bids_for_item.where("user_id != ?", self.user_id).not_cancelled
    bids_by_other_sellers.update_all(:status => "Lose", :ordered => nil, :order_id => nil, :delivered => nil, :paid => nil, :declined => nil)
  end
  
  def update_unselected_bids2(line_item)
    peer_bids = Bid.where(:line_item_id => line_item, :status => 'For-Decision').where("bid_type != ?", self.bid_type)
    peer_bids.update_all(:status => "Dropped", :ordered => nil, :order_id => nil, :delivered => nil, :paid => nil, :declined => nil)
  end
  
  def compute_bid_speed
    if entry.buyer_status == 'Relisted' || entry.buyer_status == 'Additional'
      bid_speed = (Time.now - entry.relisted).to_i
    else
      bid_speed = (Time.now - entry.online).to_i
    end
  end
  
  def cancelled?
    status.include?('Cancelled')
  end
  
  def online? # used in Seller#Show to allow deletion of bids
    status == 'Submitted' || status == 'Updated' 
  end
  
  def self.since_eval(date)
    where('bids.created_at >= ?', date)
  end
  
  def self.ordered_this_month
    where('bids.ordered >= ?', Time.now.beginning_of_month)
  end
  
end
