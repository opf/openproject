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

require_relative 'migration_utils/utils'

class UpdateAttachmentContainer < ActiveRecord::Migration
  include Migration::Utils

  def up
    say_with_time_silently "Changing container type from 'Issue' to 'WorkPackage'" do
      update <<-SQL
      UPDATE #{attachments_table}
      SET container_type = #{work_package_type}
      WHERE container_type = #{issue_type}
      SQL
    end
  end

  def down
    say_with_time_silently "Changing container type from 'WorkPackage' to 'Issue'" do
      update <<-SQL
      UPDATE #{attachments_table}
      SET container_type = #{issue_type}
      WHERE container_type = #{work_package_type}
      SQL
    end
  end

  private

  def attachments_table
    ActiveRecord::Base.connection.quote_table_name('attachments')
  end

  def issue_type
    ActiveRecord::Base.connection.quote('Issue')
  end

  def work_package_type
    ActiveRecord::Base.connection.quote('WorkPackage')
  end
end
