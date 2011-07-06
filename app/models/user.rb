class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :registerable,
  devise :database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable, :timeoutable

  # Setup accessible (or protected) attributes for your model
  # attr_accessible :username, :email, :password, :password_confirmation, :remember_me
  
  has_one :profile, :dependent => :destroy
  accepts_nested_attributes_for :profile, :allow_destroy => true, :reject_if => proc { |obj| obj.blank? }
  has_one :company, :through => :profile
  has_and_belongs_to_many :roles

  has_many :entries
  has_many :bids
  has_many :orders
  has_one :seller, :through => :order
  has_many :ratings
  has_many :ratees, :through => :ratings, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :fees
  has_many :buyers, :through => :fees
  has_many :sellers, :through => :fees
  has_many :diffs
  has_many :buyers, :through => :diffs
  has_many :sellers, :through => :diffs
  
  has_many :messages, :dependent => :destroy
  has_many :receivers, :through => :messages
  

  scope :active, where('current_sign_in_at > ?', 24.hours.ago).order('current_sign_in_at DESC')
  
  validates_presence_of :username, :email
  validates_presence_of [:password, :password_confirmation], :if => :password_required?
  
  def password_required? 
    encrypted_password.blank? || !password.blank?
  end
  
  def has_role?(rolename) 
    self.roles.find_by_name(rolename) ? true : false
  end
  
  def primary_role
    company.primary_role
  end

  def to_param 
    #{}"#{id}-#{username.downcase}"
    username.downcase
  end
  
  def self.search(search)  
    if search  
      where('username LIKE ?', "%#{search}%")  
    else  
      scoped  
    end  
  end  
  
  def username_for_menu
    username.upcase
  end
  
  def company_name
    profile.company.name.upcase
  end
  
  def power
    roles
  end
end
