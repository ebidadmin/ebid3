class CarPartsController < ApplicationController
  before_filter :initialize_cart, :except => [:index, :show]
  before_filter :check_buyer_role
  before_filter :check_admin_role, :except => [:new, :create, :search]
  respond_to :html, :js

  def index
    unless params[:orig].nil?
      @search = CarPart.name_like_all(params[:name].to_s.split).where(:id => [params[:orig], params[:new]]).ascend_by_name
    else
      @search = CarPart.name_like_all(params[:name].to_s.split).ascend_by_name
    end
    @car_parts = @search.includes(:line_items).paginate :page => params[:page], :per_page => 15
  end
  
  def show
    @car_part = CarPart.find(params[:id])
  end
  
  def new
    @car_part = CarPart.new
  end
  
  def create
    @car_part = CarPart.new(params[:car_part])
    @car_part.strip_blanks(current_user)
    if @car_part.save
      new_car_part = CarPart.last
      @item = @cart.add(new_car_part.id)
      flash[:notice] = "Successfully created car part."
      if current_user.has_role?('admin')
        redirect_to car_parts_path(:name => @car_part.name)
      else
        redirect_to :back
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
    flash[:notice] = "Deleted <strong>#{name}</strong>.".html_safe
    redirect_to :back
  end

  def search
    @search = CarPart.name_like_all(params[:name].to_s.split).ascend_by_name
    @car_parts, @car_parts_count = @search.paginate(:page => params[:page], :per_page => 12, :order => 'name ASC'), @search.count
  end
end
