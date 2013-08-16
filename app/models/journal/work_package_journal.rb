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

class Journal::WorkPackageJournal < ActiveRecord::Base
  self.table_name = "work_package_journals"

  belongs_to :journal

  @@journaled_attributes = [:type_id,
                            :project_id,
                            :subject,
                            :description,
                            :start_date,
                            :due_date,
                            :category_id,
                            :status_id,
                            :assigned_to_id,
                            :priority_id,
                            :fixed_version_id,
                            :author_id,
                            :done_ratio,
                            :estimated_hours,
                            :planning_element_status_comment,
                            :deleted_at,
                            :parent_id,
                            :responsible_id,
                            :planning_element_status_id]

  def journaled_attributes
    attributes.symbolize_keys.select{|k,_| @@journaled_attributes.include? k}
  end

end
