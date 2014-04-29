require 'roar/decorator'
require 'roar/representer/json'
require 'roar/representer/json/hal'

module WorkPackages
  class WorkPackageRepresenter < Roar::Decorator
    include Roar::Representer::JSON
    include Roar::Representer::Feature::Hypermedia
    include Roar::Representer::JSON::HAL

    property :id
    property :subject
    property :description
    property :type, getter: lambda { |arg| type.try(:name) }
    property :due_date
    property :category, getter: lambda { |arg| category.try(:name) }
    property :status, getter: lambda { |arg| status.try(:name) }
    property :priority, getter: lambda { |arg| priority.try(:name) }
    property :fixed_version, getter: lambda { |arg| fixed_version.try(:name)  }
    property :lock_version
    property :done_ratio
    property :estimated_hours
    property :start_date
    property :created_at
    property :updated_at

    link :self do
      "/work_packages/#{represented.id}"
    end

    property :project, class: Project, embedded: true do
      property :id
    end

    property :author, class: User, embedded: true do
      property :mail
    end

    property :assigned_to, as: :assignee, class: User, embedded: true do
      property :mail
    end

    property :responsible, class: User, embedded: true do
      property :mail
    end



    # collection :children, class: WorkPackage, embedded: true do
    #   property :subject
    # end
  end
end
