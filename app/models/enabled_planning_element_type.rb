class EnabledPlanningElementType < ActiveRecord::Base
  unloadable

  self.table_name = 'enabled_planning_element_types'

  include TimestampsCompatibility

  belongs_to :project,               :class_name  => 'Project',
                                     :foreign_key => 'project_id'
  belongs_to :planning_element_type, :class_name  => 'PlanningElementType',
                                     :foreign_key => 'planning_element_type_id'

  attr_accessible :planning_element_type_id

  validates_presence_of :planning_element_type, :project
end

