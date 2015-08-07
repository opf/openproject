#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

if Role.where(builtin: false).any?
  puts '***** Skipping roles as there are already some configured'
else
  Role.transaction do
    Role.new.tap do |role|
      role.name = I18n.t(:default_role_project_admin)
      role.position = 3
      role.permissions = Role.new.setable_permissions.map(&:name)
    end.save!

    Role.new.tap do |role|
      role.name = I18n.t(:default_role_member)
      role.position = 4
      role.permissions = [:view_work_packages,
                          :export_work_packages,
                          :add_work_packages,
                          :move_work_packages,
                          :edit_work_packages,
                          :add_work_package_notes,
                          :edit_own_work_package_notes,
                          :manage_work_package_relations,
                          :manage_subtasks,
                          :manage_public_queries,
                          :save_queries,
                          :view_work_package_watchers,
                          :add_work_package_watchers,
                          :delete_work_package_watchers,
                          :view_calendar,
                          :comment_news,
                          :log_time,
                          :view_time_entries,
                          :edit_own_time_entries,
                          :view_project_associations,
                          :view_timelines,
                          :edit_timelines,
                          :delete_timelines,
                          :view_reportings,
                          :edit_reportings,
                          :delete_reportings,
                          :manage_wiki,
                          :manage_wiki_menu,
                          :rename_wiki_pages,
                          :change_wiki_parent_page,
                          :delete_wiki_pages,
                          :view_wiki_pages,
                          :export_wiki_pages,
                          :view_wiki_edits,
                          :edit_wiki_pages,
                          :delete_wiki_pages_attachments,
                          :protect_wiki_pages,
                          :list_attachments,
                          :add_messages,
                          :edit_own_messages,
                          :delete_own_messages,
                          :browse_repository,
                          :view_changesets,
                          :commit_access,
                          :view_commit_author_statistics]
    end.save!

    Role.new.tap do |reader|
      reader.name = I18n.t(:default_role_reader)
      reader.position =  5
      reader.permissions = [:view_work_packages,
                            :add_work_package_notes,
                            :edit_own_work_package_notes,
                            :save_queries,
                            :view_calendar,
                            :comment_news,
                            :view_project_associations,
                            :view_timelines,
                            :view_reportings,
                            :view_wiki_pages,
                            :export_wiki_pages,
                            :view_wiki_edits,
                            :edit_wiki_pages,
                            :list_attachments,
                            :add_messages,
                            :edit_own_messages,
                            :delete_own_messages,
                            :browse_repository,
                            :view_changesets]
    end.save!

    Role.non_member.update_attributes name: I18n.t(:default_role_non_member),
                                      permissions: [:view_work_packages,
                                                    :view_calendar,
                                                    :comment_news,
                                                    :browse_repository,
                                                    :view_changesets,
                                                    :view_wiki_pages]

    Role.anonymous.update_attributes name: I18n.t(:default_role_anonymous),
                                     permissions: [:view_work_packages,
                                                   :browse_repository,
                                                   :view_changesets,
                                                   :view_wiki_pages]
  end
end
