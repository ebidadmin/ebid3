module UsersHelper
  def enabling_toggle(user)
		unless user == current_user 
	    if user.enabled  
		    ("<span id='disable'>
					| #{link_to('Disable', disable_user_url(user), :method => :put)} 
				</span>").html_safe 
		  else 
		    ("<span id='enable'>
					| #{link_to('Enable', enable_user_url(user), :method => :put)}
				</span>").html_safe
	    end 
	  end 
  end

end
