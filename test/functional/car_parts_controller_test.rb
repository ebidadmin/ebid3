require 'test_helper'

class CarPartsControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end
  
  def test_show
    get :show, :id => CarPart.first
    assert_template 'show'
  end
  
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    CarPart.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end

  def test_create_valid
    CarPart.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to car_part_url(assigns(:car_part))
  end
  
  def test_edit
    get :edit, :id => CarPart.first
    assert_template 'edit'
  end
  
  def test_update_invalid
    CarPart.any_instance.stubs(:valid?).returns(false)
    put :update, :id => CarPart.first
    assert_template 'edit'
  end

  def test_update_valid
    CarPart.any_instance.stubs(:valid?).returns(true)
    put :update, :id => CarPart.first
    assert_redirected_to car_part_url(assigns(:car_part))
  end
  
  def test_destroy
    car_part = CarPart.first
    delete :destroy, :id => car_part
    assert_redirected_to car_parts_url
    assert !CarPart.exists?(car_part.id)
  end
end
