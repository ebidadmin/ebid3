class UsersController < ApplicationController
  before_filter :check_admin_role, :only => [:index, :destroy, :enable, :disable]
  # before_filter :authenticate_user!, :except => [:new, :create]
  skip_before_filter :authenticate_user!, :only => [:new, :create]

  def index
    @search = User.order('current_sign_in_at DESC').search(params[:search])
    @users = @search.paginate(:page => params[:page], :per_page => 20)
  end
  
  def show
    if current_user.has_role?('admin')
      @user = User.find_by_username(params[:id])
    else
      @user = current_user
    end
    @profile = @user.profile
    @all_roles = Role.all
  end
  
  def new
    @user = User.new
    @user.build_profile
    @company_type = Role.find(2, 3)
  end
  
  def create
    # raise params.to_yaml
    @user = User.new(params[:user])
    @company_type = Role.find(2, 3)
    if @user.save
      flash[:notice] = "Successfully created account for #{@user.username}. Please call us at 892-5835 to activate your account."
      redirect_to @user
     else
      render :action => 'new'
    end
  end
  
  def edit
    if current_user.has_role?('admin')
      @user = User.find_by_username(params[:id])
      @company_type = Role.find(1, 2, 3)
    else
      @user = current_user
      @company_type = Role.find(2, 3)
    end
  end
  
  def update
    if current_user.has_role?('admin')
      @user = User.find_by_username(params[:id])
      @company_type = Role.find(1, 2, 3)
    else
      @user = current_user
      @company_type = Role.find(2, 3)
    end
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
    flash[:notice] = "Successfully deleted user."
    redirect_to :back
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
