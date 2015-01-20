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

class MigrateRemainingCoreSettings < ActiveRecord::Migration
  REPLACED = {
    'tracker' => 'type',
    'issue_status_updated' => 'status_updated',
    'issue_status' => 'status',
    'issue_field' => 'field',
    'updated_on' => 'updated_at'
  }
  def self.up
    # Delete old plugin settings no longer needed
    ActiveRecord::Base.connection.execute <<-SQL
        DELETE FROM #{settings_table}
        WHERE name = #{quote_value('plugin_redmine_favicon')}
        OR name = #{quote_value('plugin_chiliproject_help_link')}
      SQL
    # Rename Tracker to Type
    Setting['work_package_list_default_columns'] = replace(Setting['work_package_list_default_columns'], REPLACED)
    # Rename IssueStatus in notified events
    Setting['notified_events'] = replace(Setting['notified_events'], REPLACED)
    # Rename IssueStatus and IssueField in work_package_done_ratio
    Setting['work_package_done_ratio'] = replace(Setting['work_package_done_ratio'], REPLACED)
  end

  def self.down
    # the above delete part is inherently not reversable
    # Rename Type to Tracker
    Setting['work_package_list_default_columns'] = replace(Setting['work_package_list_default_columns'], REPLACED.invert)
    # Rename Status to IssueStatus in notified events
    Setting['notified_events'] = replace(Setting['notified_events'], REPLACED.invert)
    # Rename back to IssueStatus and IssueField in work_package_done_ratio
    Setting['work_package_done_ratio'] = replace(Setting['work_package_done_ratio'], REPLACED.invert)
  end

  private

  def replace(value, mapping)
    if value.respond_to? :map
      value.map { |s| mapping[s].nil? ? s : mapping[s] }
    else
      mapping[value].nil? ? value : mapping[value]
    end
  end

  def settings_table
    @settings_table ||= ActiveRecord::Base.connection.quote_table_name('settings')
  end

  def quote_value(s)
    ActiveRecord::Base.connection.quote(s)
  end
end
