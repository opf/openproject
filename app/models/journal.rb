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
  
  acts_as_searchable :columns => 'notes',
                     :include => :issue,
                     :project_key => "#{Issue.table_name}.project_id",
                     :date_column => "#{Issue.table_name}.created_on"
  
  acts_as_event :title => Proc.new {|o| "#{o.issue.tracker.name} ##{o.issue.id}: #{o.issue.subject}"},
                :description => :notes,
                :url => Proc.new {|o| {:controller => 'issues', :action => 'show', :id => o.issue.id}}

  def save
    # Do not save an empty journal
    (details.empty? && notes.blank?) ? false : super
  end
end
