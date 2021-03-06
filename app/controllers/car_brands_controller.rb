class CarBrandsController < ApplicationController
  before_filter :check_admin_role

  def index
    @car_brands = CarBrand.scoped.paginate(:page => params[:page], :per_page => 20)
  end
  
  def show
    @car_brand = CarBrand.find(params[:id])
  end
  
  def new
    @car_brand = CarBrand.new
  end
  
  def create
    @car_brand = CarBrand.new(params[:car_brand])
    if @car_brand.save
      flash[:notice] = "Successfully created car brand."
      redirect_to @car_brand
    else
      render :action => 'new'
    end
  end
  
  def edit
    @car_brand = CarBrand.find(params[:id])
  end
  
  def update
    @car_brand = CarBrand.find(params[:id])
    if @car_brand.update_attributes(params[:car_brand])
      flash[:notice] = "Successfully updated car brand."
      redirect_to @car_brand
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @car_brand = CarBrand.find(params[:id])
    @car_brand.destroy
    flash[:notice] = "Successfully destroyed car brand."
    redirect_to car_brands_url
  end
end
