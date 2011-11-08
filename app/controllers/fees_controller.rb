class FeesController < ApplicationController
  def destroy
    @fee = Fee.find(params[:id])
    @fee.destroy
    respond_to do |format|  
       format.html { redirect_to :back, :notice => 'Deleted fee item.' }  
       format.js   { render :nothing => true }  
     end
  end
end
