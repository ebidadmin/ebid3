class CarVariant < ActiveRecord::Base
  attr_accessible :car_brand_id, :car_model_id, :new_model, :name, :start_year, :end_year

  attr_accessor :new_model
  before_save :create_new_model
  
  belongs_to :car_brand
  belongs_to :car_model
  has_many :entries
 
  validates_presence_of :car_brand, :message => "Please select a car brand."
  validates_presence_of :car_model, :message => "Please select a car model.", :if => :new_model_blank
  validates_presence_of :name, :message => "Please put the name of the new variant."
  
  def create_new_model
    create_car_model(:name => new_model.strip, :car_brand_id => car_brand_id) unless new_model_blank 
  end
  
  def new_model_blank
    new_model.blank?
  end
end
