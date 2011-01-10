require 'test_helper'

class LineItemsControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end
  
  def test_show
    get :show, :id => LineItem.first
    assert_template 'show'
  end
  
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    LineItem.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end

  def test_create_valid
    LineItem.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to line_item_url(assigns(:line_item))
  end
  
  def test_edit
    get :edit, :id => LineItem.first
    assert_template 'edit'
  end
  
  def test_update_invalid
    LineItem.any_instance.stubs(:valid?).returns(false)
    put :update, :id => LineItem.first
    assert_template 'edit'
  end

  def test_update_valid
    LineItem.any_instance.stubs(:valid?).returns(true)
    put :update, :id => LineItem.first
    assert_redirected_to line_item_url(assigns(:line_item))
  end
  
  def test_destroy
    line_item = LineItem.first
    delete :destroy, :id => line_item
    assert_redirected_to line_items_url
    assert !LineItem.exists?(line_item.id)
  end
end
