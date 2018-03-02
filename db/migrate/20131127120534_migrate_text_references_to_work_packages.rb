#-- copyright
# OpenProject Meeting Plugin
#
# Copyright (C) 2011-2014 the OpenProject Foundation (OPF)
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

require Rails.root.join('db', 'migrate', 'migration_utils', 'text_references').to_s

class MigrateTextReferencesToWorkPackages < ActiveRecord::Migration[5.0]
  include Migration::Utils

  COLUMNS_PER_TABLE = {
    'meeting_contents' => { columns: ['text'], update_journal: true },
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
