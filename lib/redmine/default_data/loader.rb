#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
          !Role.find(:first, :conditions => {:builtin => 0}) &&
            !Type.find(:first, :conditions => {is_standard: false}) &&
            !Status.find(:first) &&
            !Enumeration.find(:first)
        end

        # Loads the default data
        # Raises a RecordNotSaved exception if something goes wrong
        def load(lang=nil)
          raise DataAlreadyLoaded.new("Some configuration data is already loaded.") unless no_data?
          set_language_if_valid(lang)

          Role.transaction do
            # Roles
            manager = Role.create! :name => l(:default_role_manager),
                                   :position => 1
            manager.permissions = manager.setable_permissions.collect {|p| p.name}
            manager.save!

            developer = Role.create!  :name => l(:default_role_developer),
                                      :position => 2,
                                      :permissions => [:manage_versions,
                                                      :manage_categories,
                                                      :view_work_packages,
                                                      :add_work_packages,
                                                      :edit_work_packages,
                                                      :manage_work_package_relations,
                                                      :manage_subtasks,
                                                      :add_work_package_notes,
                                                      :save_queries,
                                                      :view_calendar,
                                                      :log_time,
                                                      :view_time_entries,
                                                      :comment_news,
                                                      :view_wiki_pages,
                                                      :view_wiki_edits,
                                                      :edit_wiki_pages,
                                                      :delete_wiki_pages,
                                                      :add_messages,
                                                      :edit_own_messages,
                                                      :browse_repository,
                                                      :view_changesets,
                                                      :commit_access,
                                                      :view_commit_author_statistics]

            reporter = Role.create! :name => l(:default_role_reporter),
                                    :position => 3,
                                    :permissions => [:view_work_packages,
                                                    :add_work_packages,
                                                    :add_work_package_notes,
                                                    :save_queries,
                                                    :view_calendar,
                                                    :log_time,
                                                    :view_time_entries,
                                                    :comment_news,
                                                    :view_wiki_pages,
                                                    :view_wiki_edits,
                                                    :add_messages,
                                                    :edit_own_messages,
                                                    :browse_repository,
                                                    :view_changesets,
                                                    :view_commit_author_statistics]

            Role.non_member.update_attributes :name => l(:default_role_non_member),
                                              :permissions => [:view_work_packages,
                                                            :add_work_packages,
                                                            :add_work_package_notes,
                                                            :save_queries,
                                                            :view_calendar,
                                                            :view_time_entries,
                                                            :comment_news,
                                                            :view_wiki_pages,
                                                            :view_wiki_edits,
                                                            :add_messages,
                                                            :browse_repository,
                                                            :view_changesets,
                                                            :view_commit_author_statistics]

            Role.anonymous.update_attributes :name => l(:default_role_anonymous),
                                             :permissions => [:view_work_packages,
                                                           :view_calendar,
                                                           :view_time_entries,
                                                           :view_wiki_pages,
                                                           :view_wiki_edits,
                                                           :browse_repository,
                                                           :view_changesets,
                                                           :view_commit_author_statistics]

            # Colors
            colors_list = PlanningElementTypeColor.ms_project_colors
            colors = Hash[*(colors_list.map do |color|
              color.save
              color.reload
              [color.name.to_sym, color.id]
            end).flatten]

            # Types
            Type.create! :name           => l(:default_type_bug),
                         :color_id       => colors[:pjRed],
                         :is_default     => true,
                         :is_in_roadmap  => false,
                         :in_aggregation => true,
                         :is_milestone   => false,
                         :position       => 1

            Type.create! :name           => l(:default_type_feature),
                         :is_default     => true,
                         :color_id       => colors[:pjLime],
                         :is_in_roadmap  => true,
                         :in_aggregation => true,
                         :is_milestone   => false,
                         :position       => 2

            Type.create! :name           => l(:default_type_support),
                         :is_default     => true,
                         :color_id       => colors[:pjBlue],
                         :is_in_roadmap  => false,
                         :in_aggregation => true,
                         :is_milestone   => false,
                         :position       => 3

            Type.create! :name           => l(:default_type_phase),
                         :is_default     => true,
                         :color_id       => colors[:pjSilver],
                         :is_in_roadmap  => false,
                         :in_aggregation => true,
                         :is_milestone   => false,
                         :position       => 4

            Type.create! :name           => l(:default_type_milestone),
                         :is_default     => true,
                         :color_id       => colors[:pjPurple],
                         :is_in_roadmap  => true,
                         :in_aggregation => true,
                         :is_milestone   => true,
                         :position       => 5

            # Issue statuses
            new      = Status.create!(:name => l(:default_status_new), :is_closed => false, :is_default => true, :position => 1)
            specified  = Status.create!(:name => l(:default_status_specified), :is_closed => false, :is_default => false, :position => 2)
            confirmed  = Status.create!(:name => l(:default_status_confirmed), :is_closed => false, :is_default => false, :position => 3)
            to_be_scheduled  = Status.create!(:name => l(:default_status_to_be_scheduled), :is_closed => false, :is_default => false, :position => 4)
            scheduled  = Status.create!(:name => l(:default_status_scheduled), :is_closed => false, :is_default => false, :position => 5)
            in_progress  = Status.create!(:name => l(:default_status_in_progress), :is_closed => false, :is_default => false, :position => 6)
            tested  = Status.create!(:name => l(:default_status_tested), :is_closed => false, :is_default => false, :position => 7)
            on_hold  = Status.create!(:name => l(:default_status_on_hold), :is_closed => false, :is_default => false, :position => 8)
            rejected  = Status.create!(:name => l(:default_status_rejected), :is_closed => true, :is_default => false, :position => 9)
            closed    = Status.create!(:name => l(:default_status_closed), :is_closed => true, :is_default => false, :position => 10)

            # Workflow
            Type.find(:all).each { |t|
              Status.find(:all).each { |os|
                Status.find(:all).each { |ns|
                  Workflow.create!(:type_id => t.id, :role_id => manager.id, :old_status_id => os.id, :new_status_id => ns.id) unless os == ns
                }
              }
            }

            Type.find(:all).each { |t|
              [new, in_progress, resolved, feedback].each { |os|
                [in_progress, resolved, feedback, closed].each { |ns|
                  Workflow.create!(:type_id => t.id, :role_id => developer.id, :old_status_id => os.id, :new_status_id => ns.id) unless os == ns
                }
              }
            }

            Type.find(:all).each { |t|
              [new, in_progress, resolved, feedback].each { |os|
                [closed].each { |ns|
                  Workflow.create!(:type_id => t.id, :role_id => reporter.id, :old_status_id => os.id, :new_status_id => ns.id) unless os == ns
                }
              }
              Workflow.create!(:type_id => t.id, :role_id => reporter.id, :old_status_id => resolved.id, :new_status_id => feedback.id)
            }

            # Enumerations

            IssuePriority.create!(:name => l(:default_priority_low), :position => 1)
            IssuePriority.create!(:name => l(:default_priority_normal), :position => 2, :is_default => true)
            IssuePriority.create!(:name => l(:default_priority_high), :position => 3)
            IssuePriority.create!(:name => l(:default_priority_urgent), :position => 4)
            IssuePriority.create!(:name => l(:default_priority_immediate), :position => 5)

            TimeEntryActivity.create!(:name => l(:default_activity_design), :position => 1)
            TimeEntryActivity.create!(:name => l(:default_activity_development), :position => 2)
          end
          true
        end
      end
    end
  end
end
