class CompaniesController < ApplicationController
  before_filter :check_admin_role, :except => [:show, :edit, :update]

  def index
    @companies = Company.scoped.includes(:city, :role)
  end
  
  def show
    @company = Company.find(params[:id])
    @friends = @company.friends
  end
  
  def new
    @company = Company.new
    @company.friendships.build
    
  end
  
  def create
    @company = Company.new(params[:company])
    if @company.save
      flash[:notice] = "Successfully created company."
      redirect_to :back
    else
      render :action => 'new'
    end
  end
  
  def edit
    @company = Company.find(params[:id], :include => [:city, :role])
    if @company.friendships.first.nil?
      @company.friendships.build
    end
  end
 
  def update 
    @company = Company.find(params[:id])
    if @company.update_attributes(params[:company])
      flash[:notice] = "Successfully updated company."
      if current_user.has_role?('admin')
        redirect_to companies_path
      else
        redirect_to @company
      end
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @company = Company.find(params[:id])
    @company.destroy
    flash[:notice] = "Successfully destroyed company."
    redirect_to companies_url
  end
end
