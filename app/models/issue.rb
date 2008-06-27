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

class Issue < ActiveRecord::Base
  belongs_to :project
  belongs_to :tracker
  belongs_to :status, :class_name => 'IssueStatus', :foreign_key => 'status_id'
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'assigned_to_id'
  belongs_to :fixed_version, :class_name => 'Version', :foreign_key => 'fixed_version_id'
  belongs_to :priority, :class_name => 'Enumeration', :foreign_key => 'priority_id'
  belongs_to :category, :class_name => 'IssueCategory', :foreign_key => 'category_id'

  has_many :journals, :as => :journalized, :dependent => :destroy
  has_many :attachments, :as => :container, :dependent => :destroy
  has_many :time_entries, :dependent => :delete_all
  has_and_belongs_to_many :changesets, :order => "revision ASC"
  
  has_many :relations_from, :class_name => 'IssueRelation', :foreign_key => 'issue_from_id', :dependent => :delete_all
  has_many :relations_to, :class_name => 'IssueRelation', :foreign_key => 'issue_to_id', :dependent => :delete_all
  
  acts_as_customizable
  acts_as_watchable
  acts_as_searchable :columns => ['subject', "#{table_name}.description"], :include => :project, :with => {:journal => :issue}
  acts_as_event :title => Proc.new {|o| "#{o.tracker.name} ##{o.id}: #{o.subject}"},
                :url => Proc.new {|o| {:controller => 'issues', :action => 'show', :id => o.id}}                
  
  validates_presence_of :subject, :description, :priority, :project, :tracker, :author, :status
  validates_length_of :subject, :maximum => 255
  validates_inclusion_of :done_ratio, :in => 0..100
  validates_numericality_of :estimated_hours, :allow_nil => true

  def after_initialize
    if new_record?
      # set default values for new records only
      self.status ||= IssueStatus.default
      self.priority ||= Enumeration.default('IPRI')
    end
  end
  
  # Overrides Redmine::Acts::Customizable::InstanceMethods#available_custom_fields
  def available_custom_fields
    (project && tracker) ? project.all_issue_custom_fields.select {|c| tracker.custom_fields.include? c } : []
  end
  
  def copy_from(arg)
    issue = arg.is_a?(Issue) ? arg : Issue.find(arg)
    self.attributes = issue.attributes.dup
    self.custom_values = issue.custom_values.collect {|v| v.clone}
    self
  end
  
  # Move an issue to a new project and tracker
  def move_to(new_project, new_tracker = nil)
    transaction do
      if new_project && project_id != new_project.id
        # delete issue relations
        unless Setting.cross_project_issue_relations?
          self.relations_from.clear
          self.relations_to.clear
        end
        # issue is moved to another project
        self.category = nil 
        self.fixed_version = nil
        self.project = new_project
      end
      if new_tracker
        self.tracker = new_tracker
      end
      if save
        # Manually update project_id on related time entries
        TimeEntry.update_all("project_id = #{new_project.id}", {:issue_id => id})
      else
        rollback_db_transaction
        return false
      end
    end
    return true
  end
  
  def priority_id=(pid)
    self.priority = nil
    write_attribute(:priority_id, pid)
  end
  
  def estimated_hours=(h)
    write_attribute :estimated_hours, (h.is_a?(String) ? h.to_hours : h)
  end
  
  def validate
    if self.due_date.nil? && @attributes['due_date'] && !@attributes['due_date'].empty?
      errors.add :due_date, :activerecord_error_not_a_date
    end
    
    if self.due_date and self.start_date and self.due_date < self.start_date
      errors.add :due_date, :activerecord_error_greater_than_start_date
    end
    
    if start_date && soonest_start && start_date < soonest_start
      errors.add :start_date, :activerecord_error_invalid
    end
  end
  
  def validate_on_create
    errors.add :tracker_id, :activerecord_error_invalid unless project.trackers.include?(tracker)
  end
  
  def before_create
    # default assignment based on category
    if assigned_to.nil? && category && category.assigned_to
      self.assigned_to = category.assigned_to
    end
  end
  
  def before_save  
    if @current_journal
      # attributes changes
      (Issue.column_names - %w(id description)).each {|c|
        @current_journal.details << JournalDetail.new(:property => 'attr',
                                                      :prop_key => c,
                                                      :old_value => @issue_before_change.send(c),
                                                      :value => send(c)) unless send(c)==@issue_before_change.send(c)
      }
      # custom fields changes
      custom_values.each {|c|
        next if (@custom_values_before_change[c.custom_field_id]==c.value ||
                  (@custom_values_before_change[c.custom_field_id].blank? && c.value.blank?))
        @current_journal.details << JournalDetail.new(:property => 'cf', 
                                                      :prop_key => c.custom_field_id,
                                                      :old_value => @custom_values_before_change[c.custom_field_id],
                                                      :value => c.value)
      }      
      @current_journal.save
    end
    # Save the issue even if the journal is not saved (because empty)
    true
  end
  
  def after_save
    # Reload is needed in order to get the right status
    reload
    
    # Update start/due dates of following issues
    relations_from.each(&:set_issue_to_dates)
    
    # Close duplicates if the issue was closed
    if @issue_before_change && !@issue_before_change.closed? && self.closed?
      duplicates.each do |duplicate|
        # Reload is need in case the duplicate was updated by a previous duplicate
        duplicate.reload
        # Don't re-close it if it's already closed
        next if duplicate.closed?
        # Same user and notes
        duplicate.init_journal(@current_journal.user, @current_journal.notes)
        duplicate.update_attribute :status, self.status
      end
    end
  end
  
  def init_journal(user, notes = "")
    @current_journal ||= Journal.new(:journalized => self, :user => user, :notes => notes)
    @issue_before_change = self.clone
    @issue_before_change.status = self.status
    @custom_values_before_change = {}
    self.custom_values.each {|c| @custom_values_before_change.store c.custom_field_id, c.value }
    @current_journal
  end
  
  # Return true if the issue is closed, otherwise false
  def closed?
    self.status.is_closed?
  end
  
  # Users the issue can be assigned to
  def assignable_users
    project.assignable_users
  end
  
  # Returns an array of status that user is able to apply
  def new_statuses_allowed_to(user)
    statuses = status.find_new_statuses_allowed_to(user.role_for_project(project), tracker)
    statuses << status unless statuses.empty?
    statuses.uniq.sort
  end
  
  # Returns the mail adresses of users that should be notified for the issue
  def recipients
    recipients = project.recipients
    # Author and assignee are always notified unless they have been locked
    recipients << author.mail if author && author.active?
    recipients << assigned_to.mail if assigned_to && assigned_to.active?
    recipients.compact.uniq
  end
  
  def spent_hours
    @spent_hours ||= time_entries.sum(:hours) || 0
  end
  
  def relations
    (relations_from + relations_to).sort
  end
  
  def all_dependent_issues
    dependencies = []
    relations_from.each do |relation|
      dependencies << relation.issue_to
      dependencies += relation.issue_to.all_dependent_issues
    end
    dependencies
  end
  
  # Returns an array of issues that duplicate this one
  def duplicates
    relations_to.select {|r| r.relation_type == IssueRelation::TYPE_DUPLICATES}.collect {|r| r.issue_from}
  end
  
  # Returns the due date or the target due date if any
  # Used on gantt chart
  def due_before
    due_date || (fixed_version ? fixed_version.effective_date : nil)
  end
  
  def duration
    (start_date && due_date) ? due_date - start_date : 0
  end
  
  def soonest_start
    @soonest_start ||= relations_to.collect{|relation| relation.successor_soonest_start}.compact.min
  end
  
  def self.visible_by(usr)
    with_scope(:find => { :conditions => Project.visible_by(usr) }) do
      yield
    end
  end
  
  def to_s
    "#{tracker} ##{id}: #{subject}"
  end
end
