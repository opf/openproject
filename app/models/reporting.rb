class Reporting < ActiveRecord::Base
  unloadable

  self.table_name = 'reportings'

  include TimestampsCompatibility

  belongs_to :project
  belongs_to :reporting_to_project,    :class_name  => 'Project',
                                       :foreign_key => 'reporting_to_project_id'

  belongs_to :reported_project_status, :class_name  => 'ReportedProjectStatus',
                                       :foreign_key => 'reported_project_status_id'

  attr_accessible :reported_project_status_comment,
                  :reported_project_status_id

  validates_presence_of :project, :reporting_to_project

  validates_uniqueness_of :reporting_to_project_id, :scope => :project_id

  def visible?(user = User.current)
    reporting_to_project.visible?(user) && project.visible?(user)
  end

  def possible_reported_project_statuses
    reporting_to_project.project_type.present? ?
      reporting_to_project.project_type.reported_project_statuses :
      []
  end
end
