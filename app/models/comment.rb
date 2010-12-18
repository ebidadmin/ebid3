class Comment < ActiveRecord::Base
  attr_accessible :user_id, :user_type, :entry_id, :comment
  
  belongs_to :user
  belongs_to :entry
  
  validates :comment, :presence => true
end
