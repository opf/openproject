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

    def  responsible_login
      work_package.responsible.try(:login)
    end

    def responsible_login=(value)
      responsible_user = User.find(:first, conditions: ['login ilike ?', value])
      work_package.responsible = responsible_user
    end

    def responsible
      work_package.responsible
    end

    def  assignee_login
      work_package.assigned_to.try(:login)
    end

    def assignee_login=(value)
      assignee_user = User.find(:first, conditions: ['login ilike ?', value])
      work_package.assigned_to = assignee_user
    end

    def assignee
      work_package.assigned_to
    end

    def estimated_time
      { units: 'hours', value: work_package.estimated_hours }
    end

    def estimated_time=(value)
      hours = ActiveSupport::JSON.decode(value)['value']
      work_package.estimated_hours = hours
    end

    validates :subject, presence: true
  end
end
