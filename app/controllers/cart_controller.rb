class CartController < ApplicationController
  before_filter :initialize_cart
  
  def add
    @item = @cart.add(params[:part_id])
 
    if request.xhr?
      flash.now[:cart_notice] = "Added #{@item.car_part.name}"
    elsif request.post? 
      flash[:notice] = "Added #{@item.car_part.name}"
      redirect_to new_user_entry_path(current_user)
    else
      render
    end
  end
  
  def edit
    
  end
  
  def remove
    @item = @cart.remove(params[:part_id])
    
    if request.xhr?
      flash.now[:cart_notice] = "Removed 1 #{@item.car_part.name}"
      render :action => "add"
    elsif request.post?
      flash[:cart_notice] = "Removed 1 #{@item.car_part.name}"
      redirect_to new_user_entry_path(current_user)
    else
      render
    end
  end
  
  def clear
    @cart.cart_items.destroy_all
    if request.xhr?
      flash.now[:cart_notice] = "Cleared the cart."
      render :action => "add"
    elsif request.post?
      flash.now[:cart_notice] = "Cleared the cart."
      redirect_to new_user_entry_path(current_user)
    else
      render
    end
  end
  
end
