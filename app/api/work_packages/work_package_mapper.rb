module WorkPackages
  class WorkPackageMapper < Yaks::Mapper
    link :self, '/api/v3/work_packages/{id}'
    link :createChildren, '/api/v3/work_packages?parent_id={id}', method: :post
    link :update, '/api/v3/work_packages/{id}', method: :patch
    link :delete, '/api/v3/work_packages/{id}', method: :delete
    link :project, '/api/v3/projects/{project_id}'
    link :author, '/api/v3/users/{author_id}'
    link :assignee, '/api/v3/users/{assigned_to_id}'
    link :responsible, '/api/v3/users/{responsible_id}'
    link :targetVersion, '/api/v3/versions/{fixed_version_id}'
    link :projectWorkPackages, '/api/v3/work_packages?filter=project_ideql{project_id}'
    link :descendants, '/api/v3/work_packages?filter=ancestors_idscontain{id}'
    link :children, '/api/v3/work_packages?filter=parent_ideql{id}'
    link :parent, '/api/v3/work_packages?filter=children_idscontain{id}'
    link :ancestors, '/api/v3/work_packages?filter=descendants_idscontain{id}'
    link :relations, '/api/v3/work_packages/{id}/relations'

    attributes :id, :subject, :description, :type, :dueDate, :status, :priority, :percentageDone,
        :estimatedTime, :startDate, :createdAt, :updatedAt, :customFields, :_type

    def type
        object.type.name
    end

    def dueDate
        object.due_date.to_s
    end

    def status
        object.status.name
    end

    def priority
        object.priority.name
    end

    def percentageDone
        object.done_ratio
    end

    def estimatedTime
        { unit: 'hours', value: object.estimated_hours }
    end

    def startDate
        object.start_date.to_s
    end

    def createdAt
      object.created_at.to_s
    end

    def updatedAt
      object.updated_at.to_s
    end

    def customFields
        fields = [ ]
        object.custom_field_values.each do |custom_value|
            fields << { name: custom_value.custom_field.name, format: custom_value.custom_field.field_format, value: custom_value.value }
        end
        fields
    end

    def _type
        "WorkPackage"
    end
  end
end
