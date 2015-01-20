#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require_relative 'migration_utils/text_references'

class MigrateTextReferencesToIssuesAndPlanningElements < ActiveRecord::Migration
  include Migration::Utils

  COLUMNS_PER_TABLE = {
    'boards' => { columns: ['description'], update_journal: false },
    'messages' => { columns: ['content'], update_journal: false },
    'news' => { columns: ['summary', 'description'], update_journal: false },
    'projects' => { columns: ['description'], update_journal: false },
    'wiki_contents' => { columns: ['text'], update_journal: true },
    'work_packages' => { columns: ['description'], update_journal: true },
  }

  def up
    COLUMNS_PER_TABLE.each_pair do |table, options|
      say_with_time_silently "Update text references for table #{table}" do
        update_text_references(table, options[:columns], options[:update_journal])
      end
    end
  end

  def down
    COLUMNS_PER_TABLE.each_pair do |table, options|
      say_with_time_silently "Restore text references for table #{table}" do
        restore_text_references(table, options[:columns], options[:update_journal])
      end
    end
  end
end
