class CommentsController < ApplicationController
  def index
    @comments = Comment.all
  end
  
  def show
    @comment = Comment.find(params[:id])
  end
  
  def new
    @comment = Comment.new
  end
  
  def create
    session['referer'] = request.env["HTTP_REFERER"]
    @entry = Entry.find(params[:entry_id])
    @comment = @entry.comments.build(params[:comment])
    @comment.user_type = current_user.roles.first.name
    if current_user.comments << @comment
      flash[:notice] = "Successfully created comment."
      redirect_to session['referer'] 
      session['referer'] = nil
    else
      flash[:warning] = "You submitted a blank comment. Please try again."
      redirect_to session['referer'] 
    end
  end
  
  def edit
    @comment = Comment.find(params[:id])
  end
  
  def update
    @comment = Comment.find(params[:id])
    if @comment.update_attributes(params[:comment])
      flash[:notice] = "Successfully updated comment."
      redirect_to @comment
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
    flash[:notice] = "Successfully destroyed comment."
    redirect_to comments_url
  end
end
