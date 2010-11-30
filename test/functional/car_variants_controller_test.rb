require 'test_helper'

class CarVariantsControllerTest < ActionController::TestCase
  def test_index
    get :index
    assert_template 'index'
  end
  
  def test_show
    get :show, :id => CarVariant.first
    assert_template 'show'
  end
  
  def test_new
    get :new
    assert_template 'new'
  end
  
  def test_create_invalid
    CarVariant.any_instance.stubs(:valid?).returns(false)
    post :create
    assert_template 'new'
  end

  def test_create_valid
    CarVariant.any_instance.stubs(:valid?).returns(true)
    post :create
    assert_redirected_to car_variant_url(assigns(:car_variant))
  end
  
  def test_edit
    get :edit, :id => CarVariant.first
    assert_template 'edit'
  end
  
  def test_update_invalid
    CarVariant.any_instance.stubs(:valid?).returns(false)
    put :update, :id => CarVariant.first
    assert_template 'edit'
  end

  def test_update_valid
    CarVariant.any_instance.stubs(:valid?).returns(true)
    put :update, :id => CarVariant.first
    assert_redirected_to car_variant_url(assigns(:car_variant))
  end
  
  def test_destroy
    car_variant = CarVariant.first
    delete :destroy, :id => car_variant
    assert_redirected_to car_variants_url
    assert !CarVariant.exists?(car_variant.id)
  end
end
