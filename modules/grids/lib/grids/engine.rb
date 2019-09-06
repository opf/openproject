module Grids
  class Engine < ::Rails::Engine
    include OpenProject::Plugins::ActsAsOpEngine

    add_api_path :attachments_by_grid do |id|
      "#{root}/grids/#{id}/attachments"
    end

    config.to_prepare do
      query = Grids::Query

      Queries::Register.filter query, Grids::Filters::ScopeFilter
    end
  end
end
