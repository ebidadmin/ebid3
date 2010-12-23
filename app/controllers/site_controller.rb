class SiteController < ApplicationController
  before_filter :authenticate_user!, :except => [:index, :about]
  
  def index
    
  end
  
  def about
    
  end
  
  def site
    
  end
end
