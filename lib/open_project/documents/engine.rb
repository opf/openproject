module OpenProject::Documents
  class Engine < ::Rails::Engine
    engine_name :openproject_documents

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-documents',
             :author_url => "http://www.finn.de",
             :requires_openproject => ">= 3.0.0pre49" do

        menu :project_menu, :documents,
                            { :controller => '/documents', :action => 'index' },
                            :param => :project_id,
                            :caption => :label_document_plural,
                            :html => { :class => 'icon2 icon-book1' }

        permission :manage_documents, {:documents => [:new, :create, :edit, :update, :destroy, :add_attachment]}, :require => :loggedin
        permission :view_documents, :documents => [:index, :show, :download]

        Redmine::Notifiable.all << Redmine::Notifiable.new('document_added')

        Redmine::Activity.map do |activity|
          activity.register :documents, class_name: 'Activity::DocumentActivityProvider', default: false
        end
      Redmine::Search.register :documents
    end

    patches [:ApplicationHelper, :CustomFieldsHelper, :Project]

    assets %w(documents.css)

    initializer "documents.register_hooks" do
      require 'open_project/documents/hooks'
    end

    initializer 'documents.register_observers' do |app|
      ActiveRecord::Base.observers.push :document_observer
    end

    config.to_prepare do
      require_dependency 'document_category'
      require_dependency 'document_category_custom_field'
    end
  end
end
