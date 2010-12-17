class RemarksController < ApplicationController
  def index
    @remarks = Remark.all
  end
  
  def show
    @remarks = Remark.find(params[:id])
  end
  
  def new
    @remarks = Remark.new
  end
  
  def create
    @remarks = Remark.new(params[:remark])
    if @remarks.save
      flash[:notice] = "Successfully created remarks."
      redirect_to :back
    else
      render :action => 'new'
    end
  end
  
  def edit
    @remarks = Remark.find(params[:id])
  end
  
  def update
    @remarks = Remark.find(params[:id])
    if @remarks.update_attributes(params[:remarks])
      flash[:notice] = "Successfully updated remarks."
      redirect_to @remarks
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @remarks = Remark.find(params[:id])
    @remarks.destroy
    flash[:notice] = "Successfully destroyed remarks."
    redirect_to remarks_url
  end
end
