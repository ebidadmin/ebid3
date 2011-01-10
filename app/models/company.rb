class Company < ActiveRecord::Base
  attr_accessible :name, :address1, :address2, :zip_code, :city_id, :approver, :approver_position, 
  :primary_role, :friend_id, :friend_ids

  belongs_to :city
  belongs_to :role, :foreign_key => "primary_role"
  has_many :profiles
  has_many :users, :through => :profiles
  has_many :friendships, :dependent => :destroy
  has_many :friends, :through => :friendships
  
  validates_presence_of :name, :address1, :city, :approver
  validates_uniqueness_of :name, :message => "This company is already in our database."
end
