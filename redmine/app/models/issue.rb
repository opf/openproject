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

class Issue < ActiveRecord::Base

  belongs_to :project
  belongs_to :tracker
  belongs_to :status, :class_name => 'IssueStatus', :foreign_key => 'status_id'
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'
  belongs_to :assigned_to, :class_name => 'User', :foreign_key => 'assigned_to_id'
  belongs_to :fixed_version, :class_name => 'Version', :foreign_key => 'fixed_version_id'
  belongs_to :priority, :class_name => 'Enumeration', :foreign_key => 'priority_id'
  belongs_to :category, :class_name => 'IssueCategory', :foreign_key => 'category_id'

  has_many :histories, :class_name => 'IssueHistory', :dependent => true, :order => "issue_histories.created_on DESC", :include => :status
  has_many :attachments, :as => :container, :dependent => true

  has_many :custom_values, :dependent => true, :as => :customized
  has_many :custom_fields, :through => :custom_values

  validates_presence_of :subject, :description, :priority, :tracker, :author
  validates_associated :custom_values, :on => :update

  # set default status for new issues
  def before_validation
    self.status = IssueStatus.default if new_record?
  end

  def validate
    if self.due_date.nil? && @attributes['due_date'] && !@attributes['due_date'].empty?
      errors.add :due_date, :activerecord_error_not_a_date
    end
  end

  def before_create
    build_history
  end

  def long_id
    "%05d" % self.id
  end
  
  def custom_value_for(custom_field)
    self.custom_values.each {|v| return v if v.custom_field_id == custom_field.id }
    return nil
  end

private
  # Creates an history for the issue
  def build_history
    @history = self.histories.build
    @history.status = self.status
    @history.author = self.author
  end
end
