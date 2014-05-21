module WorkPackages
  class WorkPackageModel < Reform::Form
    include Composition

    model :work_package

    property :subject, on: :work_package
    property :description, on: :work_package
    property :due_date, on: :work_package
    property :percentage_done, as: :done_ratio, on: :work_package
    property :start_date, on: :work_package
    property :created_at, on: :work_package
    property :updated_at, on: :work_package
    property :author, on: :work_package
    property :project_id, on: :work_package
    property :responsible_id, on: :work_package
    property :assigned_to_id, on: :work_package

    def type
      work_package.type.name
    end

    def type=(value)
      type = Type.find(:first, conditions: ['name ilike ?', value])
      work_package.type = type
    end

    def status
      work_package.status.name
    end

    def status=(value)
      status = Status.find(:first, conditions: ['name ilike ?', value])
      work_package.status = status
    end

    def priority
      work_package.priority.name
    end

    def priority=(value)
      priority = IssuePriority.find(:first, conditions: ['name ilike ?', value])
      work_package.priority = priority
    end

    def estimated_time
      { units: 'hours', value: work_package.estimated_hours }
    end

    def estimated_time=(value)
      hours = ActiveSupport::JSON.decode(value)['value']
      work_package.estimated_hours = hours
    end

    def project_id=(value)
      work_package.project_id = value
    end

    def responsible_id=(value)
      work_package.responsible_id = value
    end

    def assigned_to_id=(value)
      work_package.assigned_to_id = value
    end

    validates :subject, presence: true
    validates_inclusion_of :project_id, in: Project.pluck(:id)
  end
end
