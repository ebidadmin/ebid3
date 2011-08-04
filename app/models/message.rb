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
end
