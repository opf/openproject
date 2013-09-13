#-- encoding: UTF-8
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

class IssueCategory < ActiveRecord::Base
  include Redmine::SafeAttributes
  belongs_to :project
  belongs_to :assigned_to, :class_name => 'Principal', :foreign_key => 'assigned_to_id'
  has_many :work_packages, :foreign_key => 'category_id', :dependent => :nullify

  attr_protected :project_id

  validates_presence_of :name
  validates_uniqueness_of :name, :scope => [:project_id]
  validates_length_of :name, :maximum => 30

  # validates that assignee is member of the issue category's project
  validates_each :assigned_to_id do |record, attr, value|
    if value # allow nil
      record.errors.add(attr, l(:error_must_be_project_member)) unless record.project.principals.map(&:id).include? value
    end
  end

  safe_attributes 'name', 'assigned_to_id'

  alias :destroy_without_reassign :destroy

  # Destroy the category
  # If a category is specified, issues are reassigned to this category
  def destroy(reassign_to = nil)
    if reassign_to && reassign_to.is_a?(IssueCategory) && reassign_to.project == self.project
      WorkPackage.update_all("category_id = #{reassign_to.id}", "category_id = #{id}")
    end
    destroy_without_reassign
  end

  def <=>(category)
    name <=> category.name
  end

  def to_s; name end
end
