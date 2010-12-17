require 'test_helper'

class RemarksControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end
  
  def test_show
    get :show, :id => Remarks.first
    assert_template 'show'
  end
  
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    Remarks.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end

  def test_create_valid
    Remarks.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to remarks_url(assigns(:remarks))
  end
  
  def test_edit
    get :edit, :id => Remarks.first
    assert_template 'edit'
  end
  
  def test_update_invalid
    Remarks.any_instance.stubs(:valid?).returns(false)
    put :update, :id => Remarks.first
    assert_template 'edit'
  end

  def test_update_valid
    Remarks.any_instance.stubs(:valid?).returns(true)
    put :update, :id => Remarks.first
    assert_redirected_to remarks_url(assigns(:remarks))
  end
  
  def test_destroy
    remarks = Remarks.first
    delete :destroy, :id => remarks
    assert_redirected_to remarks_url
    assert !Remarks.exists?(remarks.id)
  end
end
