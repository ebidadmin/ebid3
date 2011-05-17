class Rating < ActiveRecord::Base
  attr_accessible :order_id, :user_id, :ratee_id, :stars, :review

  belongs_to :user
  belongs_to :ratee, :class_name => "User"
  
  belongs_to :order, :counter_cache => true
  
  validates_presence_of :stars
  
  scope :desc, order('id DESC')
  scope :metered, where('ratings.created_at >= ?', '2011-04-16')
end
