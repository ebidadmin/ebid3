class LineItemsController < ApplicationController
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
    @line_item = LineItem.new(params[:line_item])
    if @line_item.save
      flash[:notice] = "Successfully created line item."
      redirect_to @line_item
    else
      render :action => 'new'
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

end
