class City < ActiveRecord::Base
  attr_accessible :name
  before_validation :strip_blanks
  
  has_many :companies
  has_many :entries
  
  validates_presence_of :name
  validates_uniqueness_of :name

  def strip_blanks
    self.name = self.name.strip
  end
end
