require 'test_helper'

class CarModelTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert CarModel.new.valid?
  end
end
