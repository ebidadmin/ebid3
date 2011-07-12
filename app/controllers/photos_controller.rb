class PhotosController < ApplicationController
  def new
  end
  
  def attach
    # raise params.to_yaml
    @entry = Entry.find(params[:id])
    
    if @entry.update_attributes(params[:entry])
      if @entry.line_items.present?
        redirect_to @entry, :notice => "Congratulations! Your Entry is complete. You can still Edit it, or proceed to put it online."
        EntryMailer.delay.new_entry_alert(@entry)
      else
        flash[:warning] = "Saved your photos. Please choose parts."
        redirect_to @entry
      end
    else
      flash[:warning] = "There was an error in submitting your photos.  Please check if the file formats are correct."
      redirect_to :back
    end
  end

  def destroy
  end

end
