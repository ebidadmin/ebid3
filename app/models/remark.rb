class Remark < ActiveRecord::Base
  belongs_to :user
  belongs_to :entry
  
  validates_presence_of :remark
end
