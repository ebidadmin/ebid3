class CarPartsController < ApplicationController
  def index
    @car_parts = CarPart.all
  end
  
  def show
    @car_part = CarPart.find(params[:id])
  end
  
  def new
    @car_part = CarPart.new
  end
  
  def create
    @car_part = CarPart.new(params[:car_part])
    if @car_part.save
      flash[:notice] = "Successfully created car part."
      redirect_to @car_part
    else
      render :action => 'new'
    end
  end
  
  def edit
    @car_part = CarPart.find(params[:id])
  end
  
  def update
    @car_part = CarPart.find(params[:id])
    if @car_part.update_attributes(params[:car_part])
      flash[:notice] = "Successfully updated car part."
      redirect_to @car_part
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @car_part = CarPart.find(params[:id])
    @car_part.destroy
    flash[:notice] = "Successfully destroyed car part."
    redirect_to car_parts_url
  end

  def search
    @search = CarPart.name_like_all(params[:name].to_s.split).ascend_by_name
    @car_parts, @car_parts_count = @search.paginate(:page => params[:page], :per_page => 12, :order => 'name ASC'), @search.count
  end
end
