class JavascriptsController < ApplicationController
  def dynamic_models
    @car_models = CarModel.order(:name)
    @car_variants = CarVariant.order(:name)
  end

  def dynamic_models2
    @car_models = CarModel.order(:name)
    @car_variants = CarVariant.order(:name)
  end

  def formtastic_models
    @car_models = CarModel.all
  end
end
