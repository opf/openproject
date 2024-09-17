#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class MakeProjectIdentifierUnique < ActiveRecord::Migration[6.1]
  def change
    begin
      remove_index :projects, :identifier
    rescue StandardError => e
      raise <<~MESSAGE
        Failed to remove an index from the OpenProject database: #{e.message}

        You likely have two OpenProject database schemas running at the same time since migrating
        from MySQL to PostgreSQL.

        Please follow the following guide in our forums on how to correct this error before continuing the upgrade:
        https://community.openproject.org/topics/13672?r=13736#message-13736
      MESSAGE
    end

    begin
      add_index :projects, :identifier, unique: true
    rescue StandardError => e
      raise "You have a duplicate project identifier in your database: #{e.message}"
    end
  end
end
