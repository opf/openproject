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

class ProjectAssociation < ActiveRecord::Base
  unloadable

  self.table_name = 'project_associations'

  belongs_to :project_a, :class_name  => "Project",
                         :foreign_key => 'project_a_id'
  belongs_to :project_b, :class_name  => "Project",
                         :foreign_key => 'project_b_id'

  validates_presence_of :project_a, :project_b

  attr_accessible :description

  validate :validate,
           :validate_projects_not_identical

  def projects
    [project_a, project_b].compact.uniq.sort_by(&:id)
  end

  def project(this)
    projects.find { |that| that != this }
  end

  def validate
    condition = '(project_a_id = :first AND project_b_id = :second) OR' +
                '(project_b_id = :first AND project_a_id = :second)'

    condition = "(#{condition}) AND id != :id" unless new_record?

    c = self.class.count(:conditions => [condition, {:first => project_a, :second => project_b, :id => self.id}])

    errors.add(:base, :project_association_already_exists) if c != 0

    [:project_a, :project_b].each do |field|
      project = send(field)
      if project.present? # otherwise the presence_of validation will be triggered
        errors.add(field, :project_association_not_allowed) unless project.allows_association?
      end
    end
  end

  def validate_projects_not_identical
    errors.add(:base, :identical_projects) if project_a == project_b
  end

  def visible?(user = User.current)
    projects.all? { |p| p.visible?(user) }
  end
end
