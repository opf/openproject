module Overviews
  class Engine < ::Rails::Engine
    engine_name :overviews

    include OpenProject::Plugins::ActsAsOpEngine

    initializer 'overviews.menu' do
      ::Redmine::MenuManager.map(:project_menu) do |menu|
        menu.push(:overview,
                  { controller: '/overviews/overviews', action: 'show' },
                  caption: :'overviews.label',
                  param: :project_id,
                  first: true,
                  icon: 'icon2 icon-info1')
      end
    end

    initializer 'overviews.permissions' do
      OpenProject::AccessControl.permission(:view_project)
        .actions
        .push('overviews/overviews/show')

      OpenProject::AccessControl.map do |ac_map|
        ac_map.project_module nil do |map|
          map.permission :manage_overview,
                         'overviews/overviews': ['show'],
                         public: true
        end
      end
    end

    initializer 'overviews.patches' do
      unless ::OpenProject::TextFormatting::Formats::Markdown::TextileConverter
               .included_modules
               .include?(Overviews::Patches::TextileConverterPatch)
        ::OpenProject::TextFormatting::Formats::Markdown::TextileConverter.include(Overviews::Patches::TextileConverterPatch)
      end
    end

    initializer 'overviews.conversion' do
      require Rails.root.join('config', 'constants', 'ar_to_api_conversions')

      Constants::ARToAPIConversions.add('grids/overview': 'grid')
    end

    config.to_prepare do
      Overviews::GridRegistration.register!
    end
  end
end
