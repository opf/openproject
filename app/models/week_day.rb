class WeekDay < ApplicationRecord
  def name
    day_names = I18n.t('date.day_names')
    day_names[day % 7]
  end
end
