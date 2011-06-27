class Comment < ActiveRecord::Base
  attr_accessible :user_id, :user_type, :entry_id, :comment
  
  belongs_to :user
  belongs_to :company
  belongs_to :entry
  belongs_to :order
  belongs_to :sender_company, :class_name => "Company"
  belongs_to :receiver_company, :class_name => "Company"
  belongs_to :sender, :class_name => "User"
  belongs_to :receiver, :class_name => "User"
  belongs_to :seller, :class_name => "User"
  
  validates :comment, :presence => true
end
