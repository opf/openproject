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

    property :_links, exec_context: :decorator

    def _links
        {
            root: { href: "/", title: 'OpenProject API entry point' },
            self: { href: "/work_packages/#{represented.id}", title: "represented.subject" },
            work_packages: { href: "/work_packages", title: "Work packages" },
            project_work_packages: { href: "/projects/#{represented.project.identifier}/work_packages", title: "#{represented.project.name} - Work packages" },
            descendants: { href: "/projects/#{represented.project.identifier}/work_packages?filter[ancestor_id]=#{represented.id}", title: "#{represented.subject} - Descendant work packages" },
            children: { href: "/projects/#{represented.project.identifier}/work_packages?filter[parent_id]=#{represented.id}", title: "#{represented.subject} - Children work packages" },
            create: { href: "/projects/#{represented.project.identifier}/work_packages", method: :post, title: "#{represented.project.name} - Create new work package" },
            update: { href: "/work_packages/#{represented.id}", method: :patch, title: "Update #{represented.subject}" },
            delete: { href: "/work_packages/#{represented.id}", method: :delete, title: "Delete #{represented.subject}" },
            project: { href: "/projects/#{represented.project.identifier}", title: "#{represented.project}" },
            author: { href: "/users/#{represented.author_id}", title: "?" },
            assignee: { href: "/users/#{represented.assigned_to_id}", title: "?" },
            responsible: { href: "/users/#{represented.responsible_id}", title: "?" }
        }
    end

    property :project, class: Project, decorator:  Projects::ProjectRepresenter, embedded: true
    property :author, class: User, decorator: Users::UserRepresenter, embedded: true
    property :assigned_to, as: :assignee, class: User, decorator: Users::UserRepresenter, embedded: true
    property :responsible, class: User, decorator: Users::UserRepresenter, embedded: true
  end
end
