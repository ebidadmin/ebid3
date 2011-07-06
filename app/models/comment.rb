class Comment < ActiveRecord::Base
  attr_accessible :user_id, :user_type, :entry_id, :comment
  
  belongs_to :user
  belongs_to :company
  belongs_to :entry
  belongs_to :order
  
  validates :comment, :presence => true
end
