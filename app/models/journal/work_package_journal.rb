#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
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
