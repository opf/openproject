require 'roar/representer/json'
require 'roar/decorator'

class WorkPackageRepresenter < Roar::Decorator
  include Roar::Representer::JSON
  include Roar::Representer::Feature::Hypermedia
  include Rails.application.routes.url_helpers

  property :id
  property :subject
  property :description
  property :type, getter: lambda { |*| self.type.try(:name) }
  property :due_date, as: :dueDate, getter: lambda { |*| self.due_date.try(:to_s) }
  property :status, getter: lambda { |*| self.status.try(:name) }
  property :priority, getter: lambda { |*| self.priority.try(:name) }
  property :done_ratio, as: :percentageDone
  property :estimated_time, as: :estimatedTime, exec_context: :decorator
  property :start_date, as: :startDate, getter: lambda { |*| self.start_date.try(:to_s) }
  property :created_at, as: :createdAt, getter: lambda { |*| self.created_at.try(:to_s) }
  property :updated_at, as: :updatedAt, getter: lambda { |*| self.updated_at.try(:to_s) }
  property :custom_fields, as: :customFields, exec_context: :decorator
  property :_type, exec_context: :decorator
  property :_links, exec_context: :decorator

  def estimated_time
    { units: :hours, value: represented.estimated_hours}
  end

  def custom_fields
    fields = []
    represented.custom_field_values.each do |value|
      fields << { name: value.custom_field.name, format: value.custom_field.field_format, value: value.value }
    end
    fields
  end

  def _type
    "WorkPackage"
  end

  def _links
    {
      self: { href: api_v3_work_package_path(represented.id) },
      update: { href: api_v3_work_package_path(represented.id), method: :put }
    }
  end
end
