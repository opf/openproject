module Grids
  class Engine < ::Rails::Engine
    include OpenProject::Plugins::ActsAsOpEngine

    add_api_path :attachments_by_grid do |id|
      "#{root}/grids/#{id}/attachments"
    end

    config.to_prepare do
      Queries::Register.register(Grids::Query) do
        filter Grids::Filters::ScopeFilter
      end
    end
  end
end
