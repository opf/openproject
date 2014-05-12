module WorkPackages
  class WorkPackageMapper < Yaks::Mapper
    link :self, '/api/v3/work_packages/{id}'

    attributes :id, :subject, :description, :type, :dueDate, :status, :priority, :percentageDone,
        :estimatedTime, :startDate, :createdAt, :updatedAt, :customFields, :_type

    # has_one :responsible, mapper: Users::UserMapper
    # has_many :users, mapper: Users::UserMapper, as: :members

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
