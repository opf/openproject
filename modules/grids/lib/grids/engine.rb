# frozen_string_literal: true

module Grids
  class Engine < ::Rails::Engine
    engine_name :grids

    include OpenProject::Plugins::ActsAsOpEngine

    add_api_path :attachments_by_grid do |id|
      "#{root}/grids/#{id}/attachments"
    end

    initializer "grids.permissions" do
      Rails.application.reloader.to_prepare do
        OpenProject::AccessControl.permission(:view_project)
          .controller_actions
          .push(
            "grids/widgets/project_statuses/show",
            "grids/widgets/descriptions/show",
            "grids/widgets/subitems/show"
          )

        OpenProject::AccessControl.permission(:edit_project)
          .controller_actions
          .push(
            "grids/widgets/project_statuses/update"
          )

        OpenProject::AccessControl.permission(:view_news)
          .controller_actions
          .push(
            "grids/widgets/news/show"
          )

        OpenProject::AccessControl.permission(:view_members)
          .controller_actions
          .push(
            "grids/widgets/members/show"
          )
      end
    end

    config.to_prepare do
      Queries::Register.register(Grids::Query) do
        filter Grids::Filters::ScopeFilter
      end
    end
  end
end
