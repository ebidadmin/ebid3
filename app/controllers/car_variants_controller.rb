class CarVariantsController < ApplicationController
  def index
    @car_variants = CarVariant.all
  end
  
  def show
    @car_variant = CarVariant.find(params[:id])
  end
  
  def new
    @car_variant = CarVariant.new
  end
  
  def create
    @car_variant = CarVariant.new(params[:car_variant])
    if @car_variant.save
      flash[:notice] = "Successfully created car variant."
      redirect_to @car_variant
    else
      render :action => 'new'
    end
  end
  
  def edit
    @car_variant = CarVariant.find(params[:id])
  end
  
  def update
    @car_variant = CarVariant.find(params[:id])
    if @car_variant.update_attributes(params[:car_variant])
      flash[:notice] = "Successfully updated car variant."
      redirect_to @car_variant
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @car_variant = CarVariant.find(params[:id])
    @car_variant.destroy
    flash[:notice] = "Successfully destroyed car variant."
    redirect_to car_variants_url
  end
end
