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

require_relative "migration_utils/column"

class RemoveOrphanedTokens < ActiveRecord::Migration[7.0]
  def up
    Token::Base.where.not(user_id: User.select(:id)).delete_all

    # Make sure we have bigint columns on both sides so the foreign key can be added.
    # It could be that they are of type numeric if the data was migrated from MySQL once.
    change_column_type! :users, :id, :bigint
    change_column_type! :tokens, :user_id, :bigint

    add_foreign_key :tokens, :users

    User.reset_column_information
    Token::Base.reset_column_information
  end

  def down
    remove_foreign_key :tokens, :users
  end

  def change_column_type!(table, column, type)
    Migration::MigrationUtils::Column.new(connection, table, column).change_type! type
  end
end
