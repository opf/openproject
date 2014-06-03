require 'reform/form/coercion'

module WorkPackages
  class WorkPackageModel < Reform::Form
    include Composition
    include Coercion

    model :work_package

    property :subject, on: :work_package, type: String
    property :description, on: :work_package, type: String
    property :start_date, on: :work_package, type: Date
    property :due_date, on: :work_package, type: Date
    property :created_at, on: :work_package, type: DateTime
    property :updated_at, on: :work_package, type: DateTime
    property :author, on: :work_package, type: String
    property :project_id, on: :work_package, type: Integer
    property :responsible_id, on: :work_package, type: Integer
    property :assigned_to_id, on: :work_package, type: Integer
    property :fixed_version_id, on: :work_package, type: Integer

    def type
      work_package.type.try(:name)
    end

    def type=(value)
      type = Type.find(:first, conditions: ['name ilike ?', value])
      work_package.type = type
    end

    def status
      work_package.status.try(:name)
    end

    def status=(value)
      status = Status.find(:first, conditions: ['name ilike ?', value])
      work_package.status = status
    end

    def priority
      work_package.priority.try(:name)
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

    def version_id=(value)
      work_package.fixed_version_id = value
    end

    def percentage_done
      work_package.done_ratio
    end

    def percentage_done=(value)
      work_package.done_ratio = value
    end

    validates_presence_of :subject, :project_id, :type, :author, :status
    validates_length_of :subject, maximum: 255

    validates :start_date, date: { allow_blank: true }
    validates :due_date, date: { after_or_equal_to: :start_date, message: :greater_than_start_date, allow_blank: true }, unless: -> { |wp| wp.start_date.blank? }
    validates :due_date, date: { allow_blank: true }
  end
end
