class Timelines::DefaultPlanningElementType < ActiveRecord::Base
  unloadable

  self.table_name = 'timelines_default_planning_element_types'

  include Timelines::TimestampsCompatibility

  belongs_to :project_type,          :class_name  => 'Timelines::ProjectType',
                                     :foreign_key => 'project_type_id'
  belongs_to :planning_element_type, :class_name  => 'Timelines::PlanningElementType',
                                     :foreign_key => 'planning_element_type_id'

  attr_accessible :planning_element_type_id

  validates_presence_of :planning_element_type, :project_type
end
