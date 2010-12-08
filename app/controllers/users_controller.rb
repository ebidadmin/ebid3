class UsersController < ApplicationController
  before_filter :check_admin_role, :only => [:index, :destroy, :enable]
   
  def index
    # @search = User.search(params[:search])
    @users = User.search(params[:search]).order('last_sign_in_at DESC').all
  end
  
  def show
    @user = User.find_by_username(params[:id])
    @profile = @user.profile
    @all_roles = Role.all
  end
  
  def new
    @user = User.new
    @user.build_profile
  end
  
  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "Successfully created account for #{@user.username}. Please call us at 892-5835 to activate your account."
      redirect_to @user
     else
      render :action => 'new'
    end
  end
  
  def edit
    @user = User.find_by_username(params[:id])
  end
  
  def update
    @user = User.find_by_username(params[:id])
    if @user.update_attributes(params[:user])
      flash[:notice] = "Successfully updated user."
      redirect_to @user
    else
      render :action => 'edit'
    end
  end
 
  def destroy
    @user = User.find_by_username(params[:id])
    @user.destroy
    flash[:notice] = "Successfully destroyed user."
    redirect_to users_url
  end

	def enable 
    @user = User.find_by_username(params[:id])
	  if @user.update_attribute(:enabled, true) 
	    flash[:notice] = ("User access of <strong>#{@user.username}</strong> enabled").html_safe 
	  else 
	    flash[:error] = "There was a problem enabling this user." 
	  end 
	  redirect_to :back  
	end 

	def disable # instead of deleting, user is just "disabled"
    @user = User.find_by_username(params[:id])
	  if @user.update_attribute(:enabled, false) 
	    flash[:warning] = ("User access of <strong>#{@user.username}</strong> disabled").html_safe 
	  else 
	    flash[:error] = "There was a problem disabling this user." 
	  end 
	  redirect_to :back
	end 
 
  def update_role
    @user = User.find_by_username(params[:id])
    @role = Role.find(params[:role])
    unless @user.has_role?(@role.name)
      @user.roles << @role 
	    flash[:notice] = "Role added." 
    end      
    redirect_to @user
  end
  
  def destroy_role
    @user = User.find_by_username(params[:id])
    @role = Role.find(params[:role]) 
    if @user.has_role?(@role.name)
      @user.roles.delete(@role) 
	    flash[:warning] = "Role removed." 
    end
    redirect_to @user
  end

end
