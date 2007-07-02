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
  has_many :time_entries, :dependent => :nullify
  has_many :custom_values, :dependent => :delete_all, :as => :customized
  has_many :custom_fields, :through => :custom_values
  has_and_belongs_to_many :changesets, :order => "revision ASC"
  
  has_many :relations_from, :class_name => 'IssueRelation', :foreign_key => 'issue_from_id', :dependent => :delete_all
  has_many :relations_to, :class_name => 'IssueRelation', :foreign_key => 'issue_to_id', :dependent => :delete_all
  
  acts_as_watchable
  
  validates_presence_of :subject, :description, :priority, :tracker, :author, :status
  validates_inclusion_of :done_ratio, :in => 0..100
  validates_associated :custom_values, :on => :update

  # set default status for new issues
  def before_validation
    self.status = IssueStatus.default if status.nil?
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
        @current_journal.details << JournalDetail.new(:property => 'cf', 
                                                      :prop_key => c.custom_field_id,
                                                      :old_value => @custom_values_before_change[c.custom_field_id],
                                                      :value => c.value) unless @custom_values_before_change[c.custom_field_id]==c.value
      }      
      @current_journal.save unless @current_journal.details.empty? and @current_journal.notes.empty?
    end
  end
  
  def after_save
    relations_from.each(&:set_issue_to_dates)
  end
  
  def custom_value_for(custom_field)
    self.custom_values.each {|v| return v if v.custom_field_id == custom_field.id }
    return nil
  end
  
  def init_journal(user, notes = "")
    @current_journal ||= Journal.new(:journalized => self, :user => user, :notes => notes)
    @issue_before_change = self.clone
    @custom_values_before_change = {}
    self.custom_values.each {|c| @custom_values_before_change.store c.custom_field_id, c.value }
    @current_journal
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
  
  def duration
    (start_date && due_date) ? due_date - start_date : 0
  end
  
  def soonest_start
    @soonest_start ||= relations_to.collect{|relation| relation.successor_soonest_start}.compact.min
  end
end
