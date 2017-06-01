#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

require_relative 'migration_utils/timelines'

class MigrateTimelinesEndDatePropertyInOptions < ActiveRecord::Migration[4.2]
  include Migration::Utils

  COLUMN = 'options'

  OPTIONS = {
    'end_date' => 'due_date'
  }

  def up
    say_with_time_silently 'Update timelines options' do
      update_column_values('timelines',
                           [COLUMN],
                           update_options(migrate_end_date_options(OPTIONS)),
                           options_filter(OPTIONS.keys))
    end
  end

  def down
    say_with_time_silently 'Restore timelines options' do
      update_column_values('timelines',
                           [COLUMN],
                           update_options(migrate_end_date_options(OPTIONS.invert)),
                           options_filter(OPTIONS.invert.keys))
    end
  end

  private

  def options_filter(options)
    filter([COLUMN], options)
  end

  def migrate_end_date_options(options)
    Proc.new do |timelines_opts|
      opts = rename_columns(timelines_opts, options)

      opts
    end
  end
end
