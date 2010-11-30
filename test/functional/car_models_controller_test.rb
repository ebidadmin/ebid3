require 'test_helper'

class CarModelsControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end
  
  def test_show
    get :show, :id => CarModel.first
    assert_template 'show'
  end
  
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    CarModel.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end

  def test_create_valid
    CarModel.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to car_model_url(assigns(:car_model))
  end
  
  def test_edit
    get :edit, :id => CarModel.first
    assert_template 'edit'
  end
  
  def test_update_invalid
    CarModel.any_instance.stubs(:valid?).returns(false)
    put :update, :id => CarModel.first
    assert_template 'edit'
  end

  def test_update_valid
    CarModel.any_instance.stubs(:valid?).returns(true)
    put :update, :id => CarModel.first
    assert_redirected_to car_model_url(assigns(:car_model))
  end
  
  def test_destroy
    car_model = CarModel.first
    delete :destroy, :id => car_model
    assert_redirected_to car_models_url
    assert !CarModel.exists?(car_model.id)
  end
end
