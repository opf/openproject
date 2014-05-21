require 'roar/representer/json'
require 'roar/decorator'
require 'roar/representer/json/hal'

module WorkPackages
  class WorkPackageRepresenter < Roar::Decorator
    include Roar::Representer::JSON
    include Roar::Representer::JSON::HAL
    include Roar::Representer::Feature::Hypermedia
    include Rails.application.routes.url_helpers

    property :_type, exec_context: :decorator

    link :self do
      { href: "http://localhost:3000/api/v3/work_packages/#{represented.work_package.id}", title: "Work package" }
    end

    property :id, getter: lambda { |*| work_package.id }
    property :subject
    property :type
    property :description
    property :status
    property :priority
    property :start_date
    property :due_date
    property :estimated_time
    property :percentage_done
    property :project_id, getter: lambda { |*| work_package.project.id }
    property :project_name, getter: lambda { |*| work_package.project.name }
    property :responsible_id, getter: lambda { |*| work_package.responsible.try(:id) }, render_nil: true
    property :responsible_name, getter: lambda { |*| work_package.responsible.try(:name) }, render_nil: true
    property :responsible_login, getter: lambda { |*| work_package.responsible.try(:login) }, render_nil: true
    property :responsible_mail, getter: lambda { |*| work_package.responsible.try(:mail) }, render_nil: true
    property :assignee_id, getter: lambda { |*| work_package.assigned_to.try(:id) }, render_nil: true
    property :assignee_name, getter: lambda { |*| work_package.assigned_to.try(:name) }, render_nil: true
    property :assignee_login, getter: lambda { |*| work_package.assigned_to.try(:login) }, render_nil: true
    property :assignee_mail, getter: lambda { |*| work_package.assigned_to.try(:mail) }, render_nil: true
    property :author_name, getter: lambda { |*| work_package.author.name }
    property :author_login, getter: lambda { |*| work_package.author.login }
    property :author_mail, getter: lambda { |*| work_package.author.mail }
    property :created_at
    property :updated_at

    def _type
      "WorkPackage"
    end
  end
end
