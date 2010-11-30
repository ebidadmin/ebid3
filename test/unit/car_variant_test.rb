require 'test_helper'

class CarVariantTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert CarVariant.new.valid?
  end
end
