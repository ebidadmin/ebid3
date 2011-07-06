class Company < ActiveRecord::Base
  attr_accessible :name, :address1, :address2, :zip_code, :city_id, :approver, :approver_position, 
  :primary_role, :friend_id, :friend_ids

  belongs_to :city
  belongs_to :role, :foreign_key => "primary_role"
  has_many :profiles
  has_many :entries
  has_many :orders
  has_many :users, :through => :profiles
  has_many :friendships, :dependent => :destroy
  has_many :friends, :through => :friendships
  has_many :fees
  has_many :buyer_companies, :through => :fees
  has_many :seller_companies, :through => :fees
  has_many :diffs
  has_many :buyer_companies, :through => :diffs
  has_many :seller_companies, :through => :diffs
  has_many :canvass_companies, :through => :diffs
  has_many :comments
  has_many :sender_companies, :through => :comments
  has_many :reciever_companies, :through => :comments
  
  has_many :messages, :dependent => :destroy
  has_many :receiver_companies, :through => :messages
  
  # validates_presence_of :name, :address1, :city, :approver
  validates_uniqueness_of :name, :message => "This company is already in our database."
  
end
