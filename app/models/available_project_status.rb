class AvailableProjectStatus < ActiveRecord::Base
  unloadable

  self.table_name = 'available_project_statuses'

  include TimestampsCompatibility

  belongs_to :project_type,            :class_name  => 'ProjectType',
                                       :foreign_key => 'project_type_id'
  belongs_to :reported_project_status, :class_name  => 'ReportedProjectStatus',
                                       :foreign_key => 'reported_project_status_id'

  attr_accessible :reported_project_status_id

  validates_presence_of :reported_project_status, :project_type
end
