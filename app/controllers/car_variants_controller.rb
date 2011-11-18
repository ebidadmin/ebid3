class CarVariantsController < ApplicationController
  def index
    @car_variants = CarVariant.includes(:entries).paginate(:page => params[:page], :per_page => 20)
  end
  
  def show
    @car_variant = CarVariant.find(params[:id])
  end
  
  def new
    @car_variant = CarVariant.new
  end
  
  def create
    @car_variant = CarVariant.new(params[:car_variant])
     if @car_variant.save
       flash[:notice] = "Successfully created car variant."
       if current_user.has_role?('admin')
         redirect_to car_variants_path
       else
         redirect_to new_user_entry_path(current_user)
       end
     else
       render :action => 'new'
     end
  end
  
  def edit
    session['referer'] = request.env["HTTP_REFERER"]
    @car_variant = CarVariant.find(params[:id])
  end
  
  def update
    @car_variant = CarVariant.find(params[:id])
    if @car_variant.update_attributes(params[:car_variant])
      flash[:notice] = "Successfully updated car variant."
      redirect_to session['referer']; session['referer'] = nil
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    session['referer'] = request.env["HTTP_REFERER"]
    @car_variant = CarVariant.find(params[:id])
    @car_variant.destroy
    flash[:notice] = "Successfully destroyed car variant."
    redirect_to session['referer']; session['referer'] = nil
  end

  def rationalize
    # raise params.to_yaml
    @car_variant = CarVariant.find(params[:id])
    @new_variant = CarVariant.find(params[:new_variant])
    @entries = @car_variant.entries
    @entries.update_all(:car_variant_id => @new_variant.id)
    respond_to do |format|
      format.html { redirect_to :back, :notice => 'Transferred the entries to new variant!' }
      format.js 
    end
  end
end
