#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2011-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.md for more details.
#++

class AddLockToMeetingContent < ActiveRecord::Migration
  def self.up
    add_column :meeting_contents, :locked, :boolean, :default => false
    # Check for existence of the pre-journalized MeetingContentVersions table
    add_column :meeting_content_versions, :locked, :boolean, :default => nil if table_exists? :meeting_content_versions
  end

  def self.down
    remove_column :meeting_contents, :locked
    # Check for existence of the pre-journalized MeetingContentVersions table
    remove_column :meeting_content_versions, :locked if table_exists? :meeting_content_versions
  end
end
