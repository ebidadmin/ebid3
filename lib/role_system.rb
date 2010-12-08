class RoleSystem
  protected 

	def check_role(role) 
	  unless current_user && current_user.has_role?(role) 
	    flash[:warning] = "Sorry. That page is not included in your access privileges." 
	    redirect_back_or_default(login_path)
	  end 
	end 
	
	def check_admin_role 
	  check_role('admin') 
	end 
	
	def check_buyer_role 
	  check_role('buyer') 
	end 

	def check_seller_role 
	  check_role('seller') 
	end 
end