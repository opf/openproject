require "grids/engine"
require 'grids/configuration'

module Grids
  Grids::Configuration.register_grid('Grids::MyPage', 'my_page_path')
  Grids::Configuration.register_widget('work_packages_assigned', 'Grids::MyPage')
  Grids::Configuration.register_widget('work_packages_accountable', 'Grids::MyPage')
  Grids::Configuration.register_widget('work_packages_watched', 'Grids::MyPage')
  Grids::Configuration.register_widget('work_packages_created', 'Grids::MyPage')
  Grids::Configuration.register_widget('work_packages_calendar', 'Grids::MyPage')
  Grids::Configuration.register_widget('time_entries_current_user', 'Grids::MyPage')
  Grids::Configuration.register_widget('documents', 'Grids::MyPage')
  Grids::Configuration.register_widget('news', 'Grids::MyPage')
end
