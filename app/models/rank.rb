class Rank < ActiveRecord::Base
  has_many :profiles
  
  validates_presence_of :name
  validates_uniqueness_of :name
end
