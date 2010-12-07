class JavascriptsController < ApplicationController
  def dynamic_models
    @car_models = CarModel.all
    @car_variants = CarVariant.all
  end

  def formtastic_models
    @car_models = CarModel.all
  end
end
