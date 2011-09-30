class Message < ActiveRecord::Base
  attr_accessible :user_id, :user_company_id, :receiver_id, :receiver_company_id, :entry_id, :order_id, :message, :parent_id, :open, :ancestry
  
  has_ancestry
  
  belongs_to :entry
  belongs_to :order
  belongs_to :user
  belongs_to :user_company, :class_name => "Company"
  belongs_to :receiver, :class_name => "User"
  belongs_to :receiver_company, :class_name => "Company"
  
  scope :open, where(:open => true)
  scope :closed, where(:open => false)
  
  validates_presence_of :message
  # validates_uniqueness_of :message
    
  def self.restricted(company)
    where('user_company_id = ? OR receiver_company_id = ?', company, company)
  end
  
  def create_message(current_user, msg_type, open_msg_tag = nil, receiver = nil, receiver_company = nil, entry = nil, order = nil)
    self.user_company_id = current_user.company.id
    self.user_type = current_user.roles.first.name
    self.entry_id = entry.id unless entry.blank?
    self.order_id = order.id unless order.blank?
    if msg_type == 'admin'
      self.receiver_id = 1
      self.receiver_company_id = 1
      self.open = open_msg_tag unless open_msg_tag.blank?
    elsif msg_type == 'buyer'
      self.receiver_id = entry.user_id
      self.receiver_company_id = entry.company_id
      self.open = open_msg_tag unless open_msg_tag.blank?
    elsif msg_type == 'seller'
      self.receiver_id = receiver
      self.receiver_company_id = receiver_company
      self.open = open_msg_tag unless open_msg_tag.blank?
    elsif msg_type == 'order-seller'
      self.receiver_id = order.seller_id
      self.receiver_company_id = order.seller.company.id
      self.open = open_msg_tag unless open_msg_tag.blank?
    elsif msg_type == 'public'
      self.open = true
    end
  end
  
  def self.for_cancelled_order(current_user, msg_sender, entry, order, cancelled_bids, reason)
    msg = current_user.messages.build
    if msg_sender == 'admin'
      msg.user_company_id = entry.company_id
    else
      msg.user_company_id = current_user.company.id
    end
    msg.user_type = msg_sender
    msg.entry_id = entry.id 
    
    if msg_sender == 'seller' 
      msg.receiver_id = entry.user_id
      msg.receiver_company_id = entry.company_id
    elsif msg_sender == 'buyer' || msg_sender == 'admin'
      msg.receiver_id = order.seller_id
      msg.receiver_company_id = order.seller.company.id
    end
    
    if order.bids.all?(&:cancelled?)
      msg.message = "ENTIRE ORDER cancelled *** #{cancelled_bids.collect { |b| b.line_item.part_name}.to_sentence} *** REASON: #{reason}"
      order.update_attributes(:status => "Cancelled by #{msg_sender}", :order_total => order.bids.collect(&:total).sum)
      # "ENTIRE ORDER cancelled."
    else
      msg.message = "PARTIAL ORDER cancelled *** #{cancelled_bids.collect { |b| b.line_item.part_name}.to_sentence} *** REASON: #{reason}"
      order.update_attribute(:order_total, order.order_total - cancelled_bids.collect(&:total).sum) unless  order.order_total == 0
      # "PARTIAL ORDER cancelled."
    end
    order.messages << msg
    
  end

end
