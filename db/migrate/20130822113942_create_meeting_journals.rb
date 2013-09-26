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
class CreateMeetingJournals < ActiveRecord::Migration
  def change
    create_table :meeting_journals do |t|
      t.integer  :journal_id, :null => false
      t.string   :title
      t.integer  :author_id
      t.integer  :project_id
      t.string   :location
      t.datetime :start_time
      t.float    :duration
    end

    create_table :meeting_content_journals do |t|
      t.integer  :journal_id, :null => false
      t.integer  :meeting_id
      t.integer  :author_id
      t.text     :text
      t.boolean  :locked
    end
  end
end
