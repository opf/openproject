# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

FactoryBot.define do
  factory :work_package_role do
    sequence(:name) { |n| "WorkPackage Role #{n}" }
  end

  factory :view_work_package_role, parent: :work_package_role do
    name { "Work package viewer" }
    builtin { Role::BUILTIN_WORK_PACKAGE_VIEWER }
    permissions do
      %i(view_work_packages
         export_work_packages
         show_github_content)
    end
  end

  factory :comment_work_package_role, parent: :work_package_role do
    name { "Work package commenter" }
    builtin { Role::BUILTIN_WORK_PACKAGE_COMMENTER }
    permissions do
      %i(view_work_packages
         work_package_assigned
         add_work_package_attachments
         add_work_package_notes
         edit_own_work_package_notes
         export_work_packages
         view_own_time_entries
         log_own_time
         edit_own_time_entries
         show_github_content
         view_file_links)
    end
  end

  factory :edit_work_package_role, parent: :work_package_role do
    name { |_n| "Work package editor" }
    builtin { Role::BUILTIN_WORK_PACKAGE_EDITOR }
    permissions do
      %i(view_work_packages
         edit_work_packages
         work_package_assigned
         add_work_package_notes
         edit_own_work_package_notes
         manage_work_package_relations
         copy_work_packages
         export_work_packages
         view_own_time_entries
         log_own_time
         edit_own_time_entries
         show_github_content
         view_file_links)
    end
  end
end
