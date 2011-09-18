class CarModelsController < ApplicationController
  before_filter :check_admin_role

  def index
    @car_models = CarModel.all.paginate(:page => params[:page], :per_page => 20)
  end
  
  def show
    @car_model = CarModel.find(params[:id])
  end
  
  def new
    @car_model = CarModel.new
  end
  
  def create
    @car_model = CarModel.new(params[:car_model])
    if @car_model.save
      flash[:notice] = "Successfully created car model."
      redirect_to @car_model
    else
      render :action => 'new'
    end
  end
  
  def edit
    @car_model = CarModel.find(params[:id])
  end
  
  def update
    @car_model = CarModel.find(params[:id])
    if @car_model.update_attributes(params[:car_model])
      flash[:notice] = "Successfully updated car model."
      redirect_to @car_model
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @car_model = CarModel.find(params[:id])
    @car_model.destroy
    flash[:notice] = "Successfully destroyed car model."
    redirect_to car_models_url
  end
end
