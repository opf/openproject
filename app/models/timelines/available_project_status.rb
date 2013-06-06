class Timelines::AvailableProjectStatus < ActiveRecord::Base
  unloadable

  self.table_name = 'timelines_available_project_statuses'

  include Timelines::TimestampsCompatibility

  belongs_to :project_type,            :class_name  => 'Timelines::ProjectType',
                                       :foreign_key => 'project_type_id'
  belongs_to :reported_project_status, :class_name  => 'Timelines::ReportedProjectStatus',
                                       :foreign_key => 'reported_project_status_id'

  attr_accessible :reported_project_status_id

  validates_presence_of :reported_project_status, :project_type
end
