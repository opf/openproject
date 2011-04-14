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

class Document < ActiveRecord::Base
  belongs_to :project
  belongs_to :category, :class_name => "DocumentCategory", :foreign_key => "category_id"
  acts_as_attachable :delete_permission => :manage_documents

  acts_as_journalized :event_title => Proc.new {|o| "#{l(:label_document)}: #{o.title}"},
      :event_url => Proc.new {|o| {:controller => 'documents', :action => 'show', :id => o.journaled_id}},
      :event_author => (Proc.new do |o|
        o.attachments.find(:first, :order => "#{Attachment.table_name}.created_on ASC").try(:author)
      end)

  acts_as_searchable :columns => ['title', "#{table_name}.description"], :include => :project
  
  validates_presence_of :project, :title, :category
  validates_length_of :title, :maximum => 60
  
  named_scope :visible, lambda {|*args| { :include => :project,
                                          :conditions => Project.allowed_to_condition(args.first || User.current, :view_documents) } }
  
  def visible?(user=User.current)
    !user.nil? && user.allowed_to?(:view_documents, project)
  end
  
  def after_initialize
    if new_record?
      self.category ||= DocumentCategory.default
    end
  end
  
  def updated_on
    unless @updated_on
      a = attachments.find(:first, :order => 'created_on DESC')
      @updated_on = (a && a.created_on) || created_on
    end
    @updated_on
  end
end
