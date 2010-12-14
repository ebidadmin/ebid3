class CarPartsController < ApplicationController
  before_filter :initialize_cart
  before_filter :check_buyer_role
  before_filter :check_admin_role, :except => [:new, :create, :search]

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
      new_car_part = CarPart.last
      @item = @cart.add(new_car_part.id)
      flash[:notice] = "Successfully created car part."
      if current_user.has_role?('admin')
        redirect_to car_parts_path(:name => @car_part.name)
      else
        redirect_to new_user_entry_path(current_user)
      end 
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
      redirect_to car_parts_path(:name => @car_part.name)
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @car_part = CarPart.find(params[:id])
    name = @car_part.name
    @car_part.destroy
    flash[:notice] = "Deleted <strong>#{name}</strong>."
    redirect_to :back
  end

  def search
    @search = CarPart.name_like_all(params[:name].to_s.split).ascend_by_name
    @car_parts, @car_parts_count = @search.paginate(:page => params[:page], :per_page => 12, :order => 'name ASC'), @search.count
  end
end
