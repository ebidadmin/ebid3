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
    flash[:notice] = "Successfully destroyed line item."
    redirect_to line_items_url
  end
end
