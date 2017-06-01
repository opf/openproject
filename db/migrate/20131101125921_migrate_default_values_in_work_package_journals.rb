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

require_relative 'migration_utils/utils'

class MigrateDefaultValuesInWorkPackageJournals < ActiveRecord::Migration[4.2]
  include Migration::Utils

  def up
    raise 'This migration does not support your database!' unless postgres? || mysql?

    journal_fields.each do |field|
      migrate_field field
    end
  end

  def down
    # Up migration probably is repeatable, and the destroyed data is gone.
  end

  def journal_fields
    %w(author_id status_id priority_id)
  end

  def migrate_field(field)
    if postgres?
      execute <<-SQL
        UPDATE work_package_journals AS wpj
        SET #{field} = tmp.#{field}
        FROM (
          SELECT wpj_i.id AS id, wp.#{field} AS #{field}
          FROM work_package_journals AS wpj_i
          LEFT JOIN journals AS j ON j.id = wpj_i.journal_id
          LEFT JOIN work_packages AS wp ON wp.id = j.journable_id
        ) AS tmp
        WHERE wpj.id = tmp.id AND wpj.#{field} = 0;
      SQL
    elsif mysql?
      execute <<-SQL
        UPDATE work_package_journals AS wpj
          LEFT JOIN journals AS j ON j.id = wpj.journal_id
          LEFT JOIN work_packages AS wp ON wp.id = j.journable_id
        SET wpj.#{field} = wp.#{field}
        WHERE wpj.#{field} = 0;
      SQL
    end
  end
end
