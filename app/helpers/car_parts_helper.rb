module CarPartsHelper
  def occurrence(car_part_query)
    count = car_part_query.count
    unless count < 1
      content_tag :td, (pluralize count, 'time'), :class => 'green'
    else
      content_tag :td,'none'
    end
  end
end
