class PhotosController < ApplicationController
  def new
  end
  
  def attach
    @entry = Entry.find(params[:id])
    
    if @entry.update_attributes(params[:entry])
      if @entry.line_items.present?
        redirect_to @entry, :notice => "Successfully updated your photos."
      else
        flash[:warning] = "Successfully uploaded your photos. Please select parts."
        redirect_to @entry
      end
    else
      flash[:warning] = "There was an error in submitting your photos.  Please check if you have the correct file formats (jpg, jpeg, or png)."
      redirect_to :back
    end
  end

  def destroy
  end

end
