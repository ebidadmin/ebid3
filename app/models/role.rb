class Role < ActiveRecord::Base
  attr_accessible :name

  has_and_belongs_to_many :users
  has_many :companies, :foreign_key => "primary_role"
end
