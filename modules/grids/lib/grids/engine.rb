module Grids
  class Engine < ::Rails::Engine
    isolate_namespace Grids

    include OpenProject::Plugins::ActsAsOpEngine

    config.to_prepare do
      query = Grids::Query

      Queries::Register.filter query, Grids::Filters::PageFilter
    end

    config.to_prepare do
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
  end
end
