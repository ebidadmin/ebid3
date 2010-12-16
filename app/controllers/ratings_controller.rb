class RatingsController < ApplicationController
  def index
    if params[:user_id] == 'all'
      @ratings = Rating.where(:ratee_id => current_user.company.users).desc
    else
      @ratings = Rating.where(:ratee_id => User.find_by_username(params[:user_id])).desc
    end
  end
  
  def show
    @order = Order.find(params[:order_id])
    @ratings = @order.ratings
    @entry = @order.entry
  end
  
  def new
    session['referer'] = request.env["HTTP_REFERER"]
    @order = Order.find(params[:order_id])
    @entry = @order.entry
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
      if @order.status == "Paid" && @order.ratings.where(:user_id => current_user.company.users).exists? && @order.ratings.where(:ratee_id => current_user.company.users).exists?
        @order.close
      end
      flash[:notice] = "Successfully submitted your rating. Thanks a lot!"
      redirect_to [@order, @rating]
    else
      render :action => 'new'
    end
  end
  
  def edit
    session['referer'] = request.env["HTTP_REFERER"]
    @rating = Rating.find(params[:id])
    @order = @rating.order
  end
  
  def update
    @rating = Rating.find(params[:id])
    if @rating.update_attributes(params[:rating])
      flash[:notice] = "Successfully updated rating."
      redirect_to session['referer'] #redirect_to user_ratings_path(current_user)
      session['referer'] = nil
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @rating = Rating.find(params[:id])
    @order = Order.find(@rating.order)
    if @rating.destroy
      @order.revert unless @order.status != 'Closed'
    end
    flash[:notice] = "Successfully deleted rating."
    redirect_to :back
  end
end
