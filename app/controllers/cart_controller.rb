class CartController < ApplicationController
  before_filter :initialize_cart
  
  def add
    @entry = Entry.find(params[:id])
    @line_items = @entry.line_items.includes(:car_part)
    @item = @cart.add(params[:part_id])
 
    if request.xhr?
      flash.now[:cart_notice] = "Added #{@item.car_part.name}"
    elsif request.post? 
      flash[:notice] = "Added #{@item.car_part.name}"
      # redirect_to new_user_entry_path(current_user)
    else
      render
    end
  end
  
  def remove
    @entry = Entry.find(params[:id])
    @line_items = @entry.line_items.includes(:car_part)
    @item = @cart.remove(params[:part_id])
    
    if request.xhr?
      flash.now[:cart_notice] = "Removed 1 #{@item.car_part.name}"
      render :action => "add"
    elsif request.post?
      flash[:cart_notice] = "Removed 1 #{@item.car_part.name}"
      # redirect_to new_user_entry_path(current_user)
    else
      render
    end
  end
  
  def clear
    @entry = Entry.find(params[:id])
    @line_items = @entry.line_items
    @cart.cart_items.destroy_all
    if request.xhr?
      flash.now[:cart_notice] = "Removed all temporary parts."
      render :action => "add"
    elsif request.post?
      flash.now[:cart_notice] = "Removed all temporary parts."
      # redirect_to new_user_entry_path(current_user)
    else
      render
    end
  end
  
  def show_fields
    @cart_item = CartItem.find(params[:item])
    # redirect_to :back
  end
  
  def edit_item
    @cart_item = CartItem.find(params[:item_id])

    if @cart_item.update_attributes(params[:item])
      flash[:notice] = "Successfully updated cart item."
          
      respond_to do |format|
        format.html { redirect_to new_user_entry_path(current_user) }
        format.js { flash.now[:cart_notice] = "Updated #{@cart_item.car_part.name}" }
      end      
    else
      flash[:notice] = "Something went wrong with your cart update.  Please try again."
      render
    end
  end

end
