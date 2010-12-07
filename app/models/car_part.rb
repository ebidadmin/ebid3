class CarPart < ActiveRecord::Base
  attr_accessible :name
  before_validation :strip_blanks
  
  has_many :line_items
  has_many :entries, :through => :line_items
  has_many :bids, :through => :line_items
  
  has_many :cart_items
  has_many :carts, :through => :cart_items
  
  validates_presence_of :name, :message => "^Oops. It's blank. Please type the name for the new part."
  validates_uniqueness_of :name, :message => "^Sorry, that car part is already in our list. You can either cancel, or type a unique name for the new part."
  
  protected
  
  def strip_blanks
    self.name = self.name.strip
  end
end
