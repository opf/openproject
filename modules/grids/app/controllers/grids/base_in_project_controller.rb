module ::Grids
  class BaseInProjectController < ::ApplicationController
    include OpenProject::ClientPreferenceExtractor
    before_action :find_project_by_project_id
    before_action :authorize

    def show
      gon.settings = client_preferences
      render layout: 'angular'
    end
  end
end
