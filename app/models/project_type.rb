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

class ProjectType < ActiveRecord::Base
  unloadable

  extend Pagination::Model

  self.table_name = 'project_types'

  acts_as_list
  default_scope :order => 'position ASC'

  has_many :projects, :class_name  => 'Project',
                      :foreign_key => 'project_type_id'


  has_many :available_project_statuses, :class_name  => 'AvailableProjectStatus',
                                        :foreign_key => 'project_type_id',
                                        :dependent => :destroy
  has_many :reported_project_statuses, :through => :available_project_statuses


  # has_many :default_types, :class_name => 'DefaultPlanningElementType',
  #                          :foreign_key => 'project_type_id',
  #                          :dependent => :destroy
  # has_many :types, :through => :default_types


  include ActiveModel::ForbiddenAttributesProtection

  validates_presence_of :name
  validates_inclusion_of :allows_association, :in => [true, false]

  validates_length_of :name, :maximum => 255, :unless => lambda { |e| e.name.blank? }

  scope :like, lambda { |q|
    s = "%#{q.to_s.strip.downcase}%"
    { :conditions => ["LOWER(name) LIKE :s", {:s => s}],
    :order => "name" }
  }

  def self.search_scope(query)
    # this should be all project types to which there are projects to
    # which there are dependencies from projects that the user can see
    like(query)
  end

  def self.available_grouping_project_types
    # this should be all project types to which there are projects to
    # which there are dependencies from projects that the user can see
    find(:all, :order => :name)
  end
end
