class Fee < ActiveRecord::Base
  belongs_to :buyer_company, :class_name => "Company"
  belongs_to :seller_company, :class_name => "Company"
  belongs_to :buyer, :class_name => "User"
  belongs_to :seller, :class_name => "User"
  belongs_to :entry
  belongs_to :line_item
  belongs_to :order
  belongs_to :bid
  
  scope :ordered, where(:fee_type => 'Ordered').order('created_at DESC', 'entry_id DESC')
  scope :declined, where(:fee_type => ['Declined', 'Expired']).order('created_at DESC', 'entry_id DESC')
  scope :inclusions, includes([:entry => [:car_brand, :car_model, :car_variant, :user]], [:line_item => :car_part], :seller )
  scope :with_orders, includes(:order)
  
  def self.search(search)  
    if search  
      finder = Entry.where('plate_no LIKE ? ', "%#{search}%") 
      where(:entry_id => finder)
    else  
      scoped  
    end  
  end  

  def self.by_this_seller(user)
    where(:seller_id => user)
  end

  def self.compute(bid, status, order=nil)
    f = Fee.new
    f.buyer_company_id = bid.entry.user.company.id
    f.buyer_id = bid.entry.user_id
    f.seller_company_id = bid.user.company.id
    f.seller_id = bid.user_id
    f.entry_id = bid.entry_id
    f.line_item_id = bid.line_item_id
    f.bid_id = bid.id
    f.bid_total = bid.total
    f.bid_type = bid.bid_type
    if status == 'Paid' || status == 'Closed'
      f.fee = bid.total * 0.035
      f.fee_type = 'Ordered'
      f.order_id = order if order
      f.created_at = bid.paid if bid.paid
    else
      f.fee = bid.total * 0.0025
      f.split_amount = f.fee/2
      if bid.expired
        f.created_at = bid.expired
        f.fee_type = 'Expired'
      else
        f.created_at = bid.declined
        f.fee_type = 'Declined'
      end
    end
    f.save
  end
end
