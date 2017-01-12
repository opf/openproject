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

##
# Removes all remaining Repository::Filesystem entries.
#
class RemoveFilesystemRepositories < ActiveRecord::Migration[4.2]
  include Migration::Utils

  def up

    ActiveRecord::Base.transaction do
      # Delete any changesets belonging to filesystem repositories
      ActiveRecord::Base.connection.execute <<-SQL
        DELETE FROM changesets
        WHERE repository_id IN (
          SELECT id
          FROM repositories
          WHERE type = #{filesystem_type}
        )
      SQL

      # Circumvent Repository.where(...) since this tries to load
      # the Repository::Filesystem constant and fails.
      ActiveRecord::Base.connection.execute <<-SQL
        DELETE FROM repositories
        WHERE type = #{filesystem_type}
      SQL
    end
  end

  def filesystem_type
    quote_value('Repository::Filesystem')
  end
end
