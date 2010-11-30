require 'test_helper'

class CarPartTest < ActiveSupport::TestCase
  def test_should_be_valid
    assert CarPart.new.valid?
  end
end
