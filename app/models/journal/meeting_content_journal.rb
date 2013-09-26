#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2011-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.md for more details.
#++

class Journal::MeetingContentJournal < ActiveRecord::Base
  self.table_name = "meeting_content_journals"

  belongs_to :journal
  belongs_to :meeting
  belongs_to :author, :class_name => 'User', :foreign_key => 'author_id'

  @@journaled_attributes = [:meeting_id,
                            :author_id,
                            :text,
                            :locked]

  def journaled_attributes
    attributes.symbolize_keys.select{|k,_| @@journaled_attributes.include? k}
  end

  def editable?
    false
  end
end
