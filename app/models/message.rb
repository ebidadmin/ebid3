class Message < ActiveRecord::Base
  attr_accessible :user_id, :user_company_id, :receiver_id, :receiver_company_id, :entry_id, :order_id, :message, :parent_id, :ancestry
  
  has_ancestry
  
  belongs_to :entry
  belongs_to :order
  belongs_to :user
  belongs_to :receiver, :class_name => "User"
  belongs_to :company
  belongs_to :receiver_company, :class_name => "Company"
  
  scope :open, where(:open => true)
  scope :closed, where(:open => false)
  
  validates_presence_of :message
  # validates_uniqueness_of :message
    
  def self.restricted(company)
    where('user_company_id = ? OR receiver_company_id = ?', company, company)
  end
  
  def create_message(current_user, msg_type, open_msg_tag = nil, receiver = nil, receiver_company = nil, entry = nil)
    self.user_company_id = current_user.company.id
    self.user_type = current_user.roles.first.name
    self.entry_id = entry.id unless entry.blank?
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
    elsif msg_type == 'public'
      self.open = true
    end
    
  end

end
