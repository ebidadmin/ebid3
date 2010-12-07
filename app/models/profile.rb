class Profile < ActiveRecord::Base
  attr_accessible :user_id, :company_id, :first_name, :last_name, 
  :rank_id, :phone, :fax, :birthdate, :name

  belongs_to :user
  belongs_to :company
  belongs_to :rank
  
  validates_presence_of :company, :message => "You've got to belong to a company to use this site."
  validates_presence_of :first_name, :message => 'Please type your first name.'
  validates_presence_of :last_name, :message => "Please type your last name."
  validates_presence_of :phone, :message => "What's your phone number?"
  validates_presence_of :birthdate, :message => "Don't worry, we won't reveal your true age!"

  def full_name
    [first_name, last_name].join(" ") 
  end  
  
end
