class LineItemsController < ApplicationController
  before_filter :initialize_cart, :only => [:create]
  def index
    @line_items = LineItem.all
  end
  
  def show
    @line_item = LineItem.find(params[:id])
  end
  
  def new
    @line_item = LineItem.new
  end
  
  def create
    @entry = Entry.find(params[:id])
    if @entry.line_items.blank? && @cart.cart_items.blank? 
      flash[:error] = "Wait a minute ... your parts selection is still empty! Choose parts before you proceed."
      redirect_to :back
    else #@entry.line_items.present?
      @entry.add_or_edit_line_items_from_cart(@cart) 
      @cart.destroy
      session[:cart_id] = nil 
      redirect_to attach_photos_entry_path(@entry), :notice => "Successfully added parts. Next step is to attach photos."
    end
  end
  
  def edit
    @line_item = LineItem.find(params[:id])
  end
  
  def update
    @line_item = LineItem.find(params[:id])
    if @line_item.update_attributes(params[:line_item])
      flash[:notice] = "Successfully updated line item."
      redirect_to @line_item
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @line_item = LineItem.find(params[:id])
    @line_item.destroy
    flash[:notice] = "Successfully deleted line item."
    # redirect_to line_items_url
    redirect_to :back
  end
  
  def show_fields
    @line_item = LineItem.find(params[:id])
  end

  def change
    @line_item = LineItem.find(params[:id])

    if @line_item.update_attributes(params[:item])
      @line_item.check_and_update_associated_relationships
      flash[:notice] = "Successfully updated cart item."
          
      respond_to do |format|
        format.html { redirect_to edit_user_entry_path(current_user) }
        format.js { flash.now[:cart_notice] = "Updated #{@line_item.car_part.name}" }
      end      
    else
      flash[:notice] = "Something went wrong with your cart update.  Please try again."
      render
    end
  end

  def rationalize
    @line_items = LineItem.car_part_id_eq(params[:id])
  end

  def do_rationalization
    @line_items = LineItem.car_part_id_eq(params[:orig_part])
    @line_items.update_all(:car_part_id => params[:car_part_id])
    # TODO update associated 
    flash[:notice] = "Successfully rationalized line_items."
    redirect_to car_parts_path(:orig => params[:orig_part], :new => params[:car_part_id])
  end

end
