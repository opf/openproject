class ProjectTypeScheme < ApplicationRecord
  self.table_name = "project_type_schemes"
  belongs_to :project
  belongs_to :scheme, class_name: "TypeScheme", inverse_of: :project_assignments
  validates :project_id, uniqueness: true
  validate { errors.add(:scheme, :inactive) unless scheme&.active }
end
