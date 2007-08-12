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

class IssueRelation < ActiveRecord::Base
  belongs_to :issue_from, :class_name => 'Issue', :foreign_key => 'issue_from_id'
  belongs_to :issue_to, :class_name => 'Issue', :foreign_key => 'issue_to_id'
  
  TYPE_RELATES      = "relates"
  TYPE_DUPLICATES   = "duplicates"
  TYPE_BLOCKS       = "blocks"
  TYPE_PRECEDES     = "precedes"
  
  TYPES = { TYPE_RELATES =>     { :name => :label_relates_to, :sym_name => :label_relates_to, :order => 1 },
            TYPE_DUPLICATES =>  { :name => :label_duplicates, :sym_name => :label_duplicates, :order => 2 },
            TYPE_BLOCKS =>      { :name => :label_blocks, :sym_name => :label_blocked_by, :order => 3 },
            TYPE_PRECEDES =>    { :name => :label_precedes, :sym_name => :label_follows, :order => 4 },
          }.freeze
  
  validates_presence_of :issue_from, :issue_to, :relation_type
  validates_inclusion_of :relation_type, :in => TYPES.keys
  validates_numericality_of :delay, :allow_nil => true
  validates_uniqueness_of :issue_to_id, :scope => :issue_from_id
  
  def validate
    if issue_from && issue_to
      errors.add :issue_to_id, :activerecord_error_invalid if issue_from_id == issue_to_id
      errors.add :issue_to_id, :activerecord_error_not_same_project unless issue_from.project_id == issue_to.project_id || Setting.cross_project_issue_relations?
      errors.add_to_base :activerecord_error_circular_dependency if issue_to.all_dependent_issues.include? issue_from
    end
  end
  
  def other_issue(issue)
    (self.issue_from_id == issue.id) ? issue_to : issue_from
  end
  
  def label_for(issue)
    TYPES[relation_type] ? TYPES[relation_type][(self.issue_from_id == issue.id) ? :name : :sym_name] : :unknow
  end
  
  def before_save
    if TYPE_PRECEDES == relation_type
      self.delay ||= 0
    else
      self.delay = nil
    end
    set_issue_to_dates
  end
  
  def set_issue_to_dates
    soonest_start = self.successor_soonest_start
    if soonest_start && (!issue_to.start_date || issue_to.start_date < soonest_start)
      issue_to.start_date, issue_to.due_date = successor_soonest_start, successor_soonest_start + issue_to.duration
      issue_to.save
    end
  end
  
  def successor_soonest_start
    return nil unless (TYPE_PRECEDES == self.relation_type) && (issue_from.start_date || issue_from.due_date)
    (issue_from.due_date || issue_from.start_date) + 1 + delay
  end
  
  def <=>(relation)
    TYPES[self.relation_type][:order] <=> TYPES[relation.relation_type][:order]
  end
end
