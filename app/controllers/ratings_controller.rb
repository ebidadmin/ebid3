class RatingsController < ApplicationController
  def index
    @ratings = Rating.all
  end
  
  def show
    @order = Order.find(params[:order_id])
    @ratings = @order.ratings
    @entry = @order.entry
  end
  
  def new
    @order = Order.find(params[:order_id])
    @rating = current_user.ratings.build
  end
  
  def create
    # raise params.to_yaml
    @order = Order.find(params[:order_id])
    @rating = current_user.ratings.build(params[:rating])
    if current_user.has_role?('buyer')
        @rating.ratee_id = @order.seller_id
    elsif current_user.has_role?('seller')
        @rating.ratee_id =  @order.user_id
    end
      
    if @order.ratings << @rating
      if @order.status == "Paid" && @order.ratings.where(:user_id => current_user).exists? && @order.ratings.where(:ratee_id => current_user).exists?
        @order.close
      end
      flash[:notice] = "Successfully submitted your rating. Thanks a lot!"
      redirect_to [@order, @rating]
    else
      render :action => 'new'
    end
  end
  
  def edit
    @order = Order.find(params[:order_id])
    @rating = Rating.find(params[:id])
  end
  
  def update
    @rating = Rating.find(params[:id])
    if @rating.update_attributes(params[:rating])
      flash[:notice] = "Successfully updated rating."
      redirect_to order_ratings_path
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @rating = Rating.find(params[:id])
    @rating.destroy
    flash[:notice] = "Successfully destroyed rating."
    redirect_to ratings_url
  end
end
