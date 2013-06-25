#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class PlanningElementType < ActiveRecord::Base
  unloadable

  self.table_name = 'planning_element_types'

  acts_as_list
  default_scope :order => 'position ASC'

  extend Pagination::Model

  has_many :default_planning_element_types, :class_name  => 'DefaultPlanningElementType',
                                            :foreign_key => 'planning_element_type_id',
                                            :dependent   => :delete_all
  has_many :project_types, :through => :default_planning_element_types

  has_many :enabled_planning_element_types, :class_name  => 'EnabledPlanningElementType',
                                            :foreign_key => 'planning_element_type_id',
                                            :dependent   => :delete_all
  has_many :projects, :through => :enabled_planning_element_types

  belongs_to :color, :class_name  => 'PlanningElementTypeColor',
                     :foreign_key => 'color_id'

  has_many :planning_elements, :class_name  => 'PlanningElement',
                               :foreign_key => 'planning_element_type_id',
                               :dependent   => :nullify

  include ActiveModel::ForbiddenAttributesProtection

  validates_presence_of :name
  validates_inclusion_of :in_aggregation, :is_default, :is_milestone, :in => [true, false]

  validates_length_of :name, :maximum => 255, :unless => lambda { |e| e.name.blank? }

  scope :like, lambda { |q|
    s = "%#{q.to_s.strip.downcase}%"
    { :conditions => ["LOWER(name) LIKE :s", {:s => s}],
    :order => "name" }
  }

  def self.search_scope(query)
    like(query)
  end

  def enabled_in?(object)
    case object
    when ProjectType
      object.planning_element_types.include?(self)
    when Project
      object.planning_element_types.include?(self)
    else
      false
    end
  end

  def available_colors
    PlanningElementTypeColor.all
  end
end
