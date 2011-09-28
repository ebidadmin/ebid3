class CarPartsController < ApplicationController
  before_filter :initialize_cart, :except => [:index, :show]
  before_filter :check_buyer_role
  before_filter :check_admin_role, :except => [:new, :create, :search, :add_more]
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
    @entry = Entry.find(params[:id])
    @line_items = @entry.line_items.includes(:car_part)
    @car_part = CarPart.new(params[:car_part])
    @car_part.strip_blanks(current_user)
    respond_to do |format|
      if @car_part.save
        new_car_part = CarPart.last
        @item = @cart.add(new_car_part.id)
        flash[:notice] = "Successfully created car part."
        if current_user.has_role?('admin')
          format.html { redirect_to car_parts_path(:name => @car_part.name) }
          format.js { flash.now[:cart_notice] = "Successfully created #{@car_part.name}" }
        else
          format.html { redirect_to edit_entry_path(@entry) }
          format.js { flash.now[:cart_notice] = "Successfully created #{@car_part.name}" }
        end 
      else
        format.html { render :action => 'new' }
        format.js { flash.now[:cart_notice] = "A part named #{@car_part.name.upcase} is already in our database. Please try again." }
      end
    end
  end
  
  def edit
    @car_part = CarPart.find(params[:id])
  end
  
  def update
    @car_part = CarPart.find(params[:id])
    @car_part.strip_blanks(current_user)
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
    @entry = Entry.find(params[:id])
    @search = CarPart.name_like_all(params[:name].to_s.split).order(:name)
    @car_parts, @car_parts_count = @search.paginate(:page => params[:page], :per_page => 96), @search.count
    # respond_with @car_parts
    respond_to do |format|
      format.html { redirect_to :back }
      format.js
    end
  end
  
  def add_more
    @entry = Entry.find(params[:id])
    @line_items = @entry.line_items.includes(:car_part)
    respond_to do |format|
      format.html { redirect_to :back }
      format.js { flash.now[:cart_notice] = "Ready to add more parts ..." }
    end
    
  end
end
