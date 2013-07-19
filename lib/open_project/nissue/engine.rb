require 'rails/engine'

module OpenProject::Nissue
  class Engine < ::Rails::Engine

    engine_name :openproject_nissue

    config.autoload_paths += Dir["#{config.root}/lib/"]

    config.to_prepare do
      require_dependency 'open_project/nissue/view'
      require_dependency 'open_project/nissue/changeset_view'
      require_dependency 'open_project/nissue/paragraph'
      require_dependency 'open_project/nissue/empty_paragraph'
      require_dependency 'open_project/nissue/simple_paragraph'
      require_dependency 'open_project/nissue/journal_view'
      require_dependency 'open_project/nissue/issue_view'
      require_dependency 'open_project/nissue/issue_view/avatar'
      require_dependency 'open_project/nissue/issue_view/custom_field_paragraph'
      require_dependency 'open_project/nissue/issue_view/description_paragraph'
      require_dependency 'open_project/nissue/issue_view/estimated_time_paragraph'
      require_dependency 'open_project/nissue/issue_view/fields_paragraph'
      require_dependency 'open_project/nissue/issue_view/heading'
      require_dependency 'open_project/nissue/issue_view/related_issues_paragraph'
      require_dependency 'open_project/nissue/issue_view/spent_time_paragraph'
      require_dependency 'open_project/nissue/issue_view/sub_issues_paragraph'
      require_dependency 'open_project/nissue/issue_view/title'
    end

    config.after_initialize do
      spec = Bundler.environment.specs['openproject-nissue'][0]
      Redmine::Plugin.register :openproject_nissue do
        name 'OpenProject Nissue'
        author ((spec.authors.kind_of? Array) ? spec.authors[0] : spec.authors)
        author_url spec.homepage
        url 'https://www.openproject.org/projects/nissue'
        description spec.description
        version OpenProject::Nissue::VERSION

        requires_openproject ">= 3.0.0pre5"
      end
    end
  end
end
