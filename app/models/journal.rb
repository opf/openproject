# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

class Journal < ActiveRecord::Base
  belongs_to :journalized, :polymorphic => true
  # added as a quick fix to allow eager loading of the polymorphic association
  # since always associated to an issue, for now
  belongs_to :issue, :foreign_key => :journalized_id
  
  belongs_to :user
  has_many :details, :class_name => "JournalDetail", :dependent => :delete_all
  attr_accessor :indice
  
  acts_as_event :title => Proc.new {|o| status = ((s = o.new_status) ? " (#{s})" : nil); "#{o.issue.tracker} ##{o.issue.id}#{status}: #{o.issue.subject}" },
                :description => :notes,
                :author => :user,
                :type => Proc.new {|o| (s = o.new_status) ? (s.is_closed? ? 'issue-closed' : 'issue-edit') : 'issue-note' },
                :url => Proc.new {|o| {:controller => 'issues', :action => 'show', :id => o.issue.id, :anchor => "change-#{o.id}"}}

  acts_as_activity_provider :type => 'issues',
                            :permission => :view_issues,
                            :author_key => :user_id,
                            :find_options => {:include => [{:issue => :project}, :details, :user],
                                              :conditions => "#{Journal.table_name}.journalized_type = 'Issue' AND" +
                                                             " (#{JournalDetail.table_name}.prop_key = 'status_id' OR #{Journal.table_name}.notes <> '')"}
  
  def save
    # Do not save an empty journal
    (details.empty? && notes.blank?) ? false : super
  end
  
  # Returns the new status if the journal contains a status change, otherwise nil
  def new_status
    c = details.detect {|detail| detail.prop_key == 'status_id'}
    (c && c.value) ? IssueStatus.find_by_id(c.value.to_i) : nil
  end
  
  def new_value_for(prop)
    c = details.detect {|detail| detail.prop_key == prop}
    c ? c.value : nil
  end
  
  def editable_by?(usr)
    usr && usr.logged? && (usr.allowed_to?(:edit_issue_notes, project) || (self.user == usr && usr.allowed_to?(:edit_own_issue_notes, project)))
  end
  
  def project
    journalized.respond_to?(:project) ? journalized.project : nil
  end
  
  def attachments
    journalized.respond_to?(:attachments) ? journalized.attachments : nil
  end
end
