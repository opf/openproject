# redMine - project management software
# Copyright (C) 2006-2007  Jean-Philippe Lang
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

module Redmine
  module DefaultData
    class DataAlreadyLoaded < Exception; end

    module Loader
      include GLoc
    
      class << self
        # Returns true if no data is already loaded in the database
        # otherwise false
        def no_data?
          !Role.find(:first, :conditions => {:builtin => 0}) &&
            !Tracker.find(:first) &&
            !IssueStatus.find(:first) &&
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
            
            developper = Role.create! :name => l(:default_role_developper), 
                                      :position => 2, 
                                      :permissions => [:manage_versions, 
                                                      :manage_categories,
                                                      :add_issues,
                                                      :edit_issues,
                                                      :manage_issue_relations,
                                                      :add_issue_notes,
                                                      :save_queries,
                                                      :view_gantt,
                                                      :view_calendar,
                                                      :log_time,
                                                      :view_time_entries,
                                                      :comment_news,
                                                      :view_documents,
                                                      :view_wiki_pages,
                                                      :view_wiki_edits,
                                                      :edit_wiki_pages,
                                                      :delete_wiki_pages,
                                                      :add_messages,
                                                      :view_files,
                                                      :manage_files,
                                                      :browse_repository,
                                                      :view_changesets,
                                                      :commit_access]
            
            reporter = Role.create! :name => l(:default_role_reporter),
                                    :position => 3,
                                    :permissions => [:add_issues,
                                                    :add_issue_notes,
                                                    :save_queries,
                                                    :view_gantt,
                                                    :view_calendar,
                                                    :log_time,
                                                    :view_time_entries,
                                                    :comment_news,
                                                    :view_documents,
                                                    :view_wiki_pages,
                                                    :view_wiki_edits,
                                                    :add_messages,
                                                    :view_files,
                                                    :browse_repository,
                                                    :view_changesets]
                        
            Role.non_member.update_attribute :permissions, [:add_issues,
                                                            :add_issue_notes,
                                                            :save_queries,
                                                            :view_gantt,
                                                            :view_calendar,
                                                            :view_time_entries,
                                                            :comment_news,
                                                            :view_documents,
                                                            :view_wiki_pages,
                                                            :view_wiki_edits,
                                                            :add_messages,
                                                            :view_files,
                                                            :browse_repository,
                                                            :view_changesets]
          
            Role.anonymous.update_attribute :permissions, [:view_gantt,
                                                           :view_calendar,
                                                           :view_time_entries,
                                                           :view_documents,
                                                           :view_wiki_pages,
                                                           :view_wiki_edits,
                                                           :view_files,
                                                           :browse_repository,
                                                           :view_changesets]
                                                             
            # Trackers
            Tracker.create!(:name => l(:default_tracker_bug),     :is_in_chlog => true,  :is_in_roadmap => false, :position => 1)
            Tracker.create!(:name => l(:default_tracker_feature), :is_in_chlog => true,  :is_in_roadmap => true,  :position => 2)
            Tracker.create!(:name => l(:default_tracker_support), :is_in_chlog => false, :is_in_roadmap => false, :position => 3)
            
            # Issue statuses
            new       = IssueStatus.create!(:name => l(:default_issue_status_new), :is_closed => false, :is_default => true, :position => 1)
            assigned  = IssueStatus.create!(:name => l(:default_issue_status_assigned), :is_closed => false, :is_default => false, :position => 2)
            resolved  = IssueStatus.create!(:name => l(:default_issue_status_resolved), :is_closed => false, :is_default => false, :position => 3)
            feedback  = IssueStatus.create!(:name => l(:default_issue_status_feedback), :is_closed => false, :is_default => false, :position => 4)
            closed    = IssueStatus.create!(:name => l(:default_issue_status_closed), :is_closed => true, :is_default => false, :position => 5)
            rejected  = IssueStatus.create!(:name => l(:default_issue_status_rejected), :is_closed => true, :is_default => false, :position => 6)
            
            # Workflow
            Tracker.find(:all).each { |t|
              IssueStatus.find(:all).each { |os|
                IssueStatus.find(:all).each { |ns|
                  Workflow.create!(:tracker_id => t.id, :role_id => manager.id, :old_status_id => os.id, :new_status_id => ns.id) unless os == ns
                }        
              }      
            }
            
            Tracker.find(:all).each { |t|
              [new, assigned, resolved, feedback].each { |os|
                [assigned, resolved, feedback, closed].each { |ns|
                  Workflow.create!(:tracker_id => t.id, :role_id => developper.id, :old_status_id => os.id, :new_status_id => ns.id) unless os == ns
                }        
              }      
            }
            
            Tracker.find(:all).each { |t|
              [new, assigned, resolved, feedback].each { |os|
                [closed].each { |ns|
                  Workflow.create!(:tracker_id => t.id, :role_id => reporter.id, :old_status_id => os.id, :new_status_id => ns.id) unless os == ns
                }        
              }
              Workflow.create!(:tracker_id => t.id, :role_id => reporter.id, :old_status_id => resolved.id, :new_status_id => feedback.id)
            }
          
            # Enumerations
            Enumeration.create!(:opt => "DCAT", :name => l(:default_doc_category_user), :position => 1)
            Enumeration.create!(:opt => "DCAT", :name => l(:default_doc_category_tech), :position => 2)
          
            Enumeration.create!(:opt => "IPRI", :name => l(:default_priority_low), :position => 1)
            Enumeration.create!(:opt => "IPRI", :name => l(:default_priority_normal), :position => 2, :is_default => true)
            Enumeration.create!(:opt => "IPRI", :name => l(:default_priority_high), :position => 3)
            Enumeration.create!(:opt => "IPRI", :name => l(:default_priority_urgent), :position => 4)
            Enumeration.create!(:opt => "IPRI", :name => l(:default_priority_immediate), :position => 5)
          
            Enumeration.create!(:opt => "ACTI", :name => l(:default_activity_design), :position => 1)
            Enumeration.create!(:opt => "ACTI", :name => l(:default_activity_development), :position => 2)
          end
          true
        end
      end
    end
  end
end
