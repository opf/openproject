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

module Redmine
  module DefaultData
    class DataAlreadyLoaded < Exception; end

    module Loader
      include Redmine::I18n

      class << self
        # Returns true if no data is already loaded in the database
        # otherwise false
        def no_data?
          !Role.find(:first, conditions: { builtin: 0 }) &&
            !Type.find(:first, conditions: { is_standard: false }) &&
            !Status.find(:first) &&
            !Enumeration.find(:first)
        end

        # Loads the default data
        # Raises a RecordNotSaved exception if something goes wrong
        def load(lang = nil)
          raise DataAlreadyLoaded.new('Some configuration data is already loaded.') unless no_data?
          set_language_if_valid(lang)

          Role.transaction do
            # Roles
            manager = Role.create! name: l(:default_role_manager),
                                   position: 3
            manager.permissions = manager.setable_permissions.map(&:name)
            manager.save!

            member = Role.create! name: l(:default_role_member),
                                  position: 4,
                                  permissions: [:view_work_packages,
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

            reader = Role.create! name: l(:default_role_reader),
                                  position: 5,
                                  permissions: [:view_work_packages,
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

            Role.non_member.update_attributes name: l(:default_role_non_member),
                                              permissions: [:view_work_packages,
                                                            :view_calendar,
                                                            :comment_news,
                                                            :browse_repository,
                                                            :view_changesets,
                                                            :view_wiki_pages]

            Role.anonymous.update_attributes name: l(:default_role_anonymous),
                                             permissions: [:view_work_packages,
                                                           :browse_repository,
                                                           :view_changesets,
                                                           :view_wiki_pages]

            # Colors
            colors_list = PlanningElementTypeColor.colors
            colors = Hash[*(colors_list.map do |color|
              color.save
              color.reload
              [color.name.to_sym, color.id]
            end).flatten]

            # Types
            task = Type.create! name:           l(:default_type_task),
                                color_id:       colors[:Mint],
                                is_default:     false,
                                is_in_roadmap:  true,
                                in_aggregation: true,
                                is_milestone:   false,
                                position:       1

            deliverable = Type.create! name:           l(:default_type_deliverable),
                                       is_default:     false,
                                       color_id:       colors[:Orange],
                                       is_in_roadmap:  true,
                                       in_aggregation: true,
                                       is_milestone:   false,
                                       position:       2

            milestone = Type.create! name:           l(:default_type_milestone),
                                     is_default:     true,
                                     color_id:       colors[:Purple],
                                     is_in_roadmap:  false,
                                     in_aggregation: true,
                                     is_milestone:   true,
                                     position:       3

            phase = Type.create! name:           l(:default_type_phase),
                                 is_default:     true,
                                 color_id:       colors[:Lime],
                                 is_in_roadmap:  false,
                                 in_aggregation: true,
                                 is_milestone:   false,
                                 position:       4

            bug = Type.create! name:           l(:default_type_bug),
                               is_default:     false,
                               color_id:       colors[:'Red-bright'],
                               is_in_roadmap:  true,
                               in_aggregation: true,
                               is_milestone:   false,
                               position:       5

            feature = Type.create! name:           l(:default_type_feature),
                                   is_default:     false,
                                   color_id:       colors[:Blue],
                                   is_in_roadmap:  true,
                                   in_aggregation: true,
                                   is_milestone:   false,
                                   position:       6

            none = Type.standard_type

            # Issue statuses
            new      = Status.create!(name: l(:default_status_new), is_closed: false, is_default: true, position: 1)
            specified  = Status.create!(name: l(:default_status_specified), is_closed: false, is_default: false, position: 2)
            confirmed  = Status.create!(name: l(:default_status_confirmed), is_closed: false, is_default: false, position: 3)
            to_be_scheduled  = Status.create!(name: l(:default_status_to_be_scheduled), is_closed: false, is_default: false, position: 4)
            scheduled  = Status.create!(name: l(:default_status_scheduled), is_closed: false, is_default: false, position: 5)
            in_progress  = Status.create!(name: l(:default_status_in_progress), is_closed: false, is_default: false, position: 6)
            tested  = Status.create!(name: l(:default_status_tested), is_closed: false, is_default: false, position: 7)
            on_hold  = Status.create!(name: l(:default_status_on_hold), is_closed: false, is_default: false, position: 8)
            rejected  = Status.create!(name: l(:default_status_rejected), is_closed: true, is_default: false, position: 9)
            closed    = Status.create!(name: l(:default_status_closed), is_closed: true, is_default: false, position: 10)

            # Workflow
            statuses_for_task = [new, in_progress, on_hold, rejected, closed]
            statuses_for_deliverable = [new, specified, in_progress, on_hold, rejected, closed]
            statuses_for_none = [new, in_progress, rejected, closed]
            statuses_for_milestone = [new, to_be_scheduled, scheduled, in_progress, on_hold, rejected, closed]
            statuses_for_phase = statuses_for_milestone
            statuses_for_bug = [new, confirmed, in_progress, tested, on_hold, rejected, closed]
            statuses_for_feature = [new, specified, confirmed, in_progress, tested, on_hold, rejected, closed]
            # Give each type its own workflow. Possible statuses are stored in one of the arrays above.
            # Every status from the array gets a workflow to every other status from the array.
            ['task', 'deliverable', 'none', 'milestone', 'phase', 'bug', 'feature'].each { |t|
              (eval 'statuses_for_'.concat(t)).each { |os|
                (eval 'statuses_for_'.concat(t)).each { |ns|
                  [manager.id, member.id].each { |role_id|
                    Workflow.create!(type_id: (eval t).id, role_id: role_id, old_status_id: os.id, new_status_id: ns.id) unless os == ns
                  }
                }
              }
            }

            # Enumerations

            IssuePriority.create!(name: l(:default_priority_low), position: 1)
            IssuePriority.create!(name: l(:default_priority_normal), position: 2, is_default: true)
            IssuePriority.create!(name: l(:default_priority_high), position: 3)
            IssuePriority.create!(name: l(:default_priority_immediate), position: 5)

            TimeEntryActivity.create!(name: l(:default_activity_management), position: 1, is_default: true)
            TimeEntryActivity.create!(name: l(:default_activity_design), position: 2)
            TimeEntryActivity.create!(name: l(:default_activity_development), position: 3)
            TimeEntryActivity.create!(name: l(:default_activity_testing), position: 4)
            TimeEntryActivity.create!(name: l(:default_activity_Support), position: 5)
            TimeEntryActivity.create!(name: l(:default_activity_Other), position: 6)

            ReportedProjectStatus.create!(name: l(:default_reported_project_status_green), is_default: true)
            ReportedProjectStatus.create!(name: l(:default_reported_project_status_amber), is_default: false)
            ReportedProjectStatus.create!(name: l(:default_reported_project_status_red), is_default: false)

            # Project types

            ProjectType.create!(name: l(:default_project_type_customer))
            ProjectType.create!(name: l(:default_project_type_internal))

            reported_status_ids = ReportedProjectStatus.find(:all).map(&:id)
            ProjectType.find(:all).each { |project|
              project.update_attributes(reported_project_status_ids: reported_status_ids)
            }

            Setting['notified_events'] = ['work_package_added', \
                                          'work_package_updated',\
                                          'work_package_note_added',\
                                          'work_package_updated',\
                                          'status_updated',\
                                          'work_package_updated',\
                                          'work_package_priority_updated',\
                                          'work_package_updated',\
                                          'news_added', 'news_comment_added',\
                                          'file_added',\
                                          'message_posted',\
                                          'wiki_content_added',\
                                          'wiki_content_updated']
          end
          true
        end
      end
    end
  end
end
