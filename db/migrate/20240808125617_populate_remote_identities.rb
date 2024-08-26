# frozen_string_literal: true

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

require_relative "migration_utils/utils"

class PopulateRemoteIdentities < ActiveRecord::Migration[7.1]
  include ::Migration::Utils

  def up
    execute_sql <<~SQL.squish
      INSERT INTO remote_identities(user_id, oauth_client_id, origin_user_id, created_at, updated_at)
      SELECT DISTINCT ON (user_id, oauth_client_id) user_id, oauth_client_id, origin_user_id, created_at, updated_at
      FROM oauth_client_tokens
      WHERE oauth_client_tokens.origin_user_id IS NOT NULL
    SQL

    execute_sql "UPDATE oauth_client_tokens SET origin_user_id = NULL"
  end

  def down
    execute_sql <<~SQL.squish
      UPDATE oauth_client_tokens
      SET origin_user_id = remote_identities.origin_user_id
      FROM remote_identities
      WHERE oauth_client_tokens.user_id = remote_identities.user_id
        AND oauth_client_tokens.oauth_client_id = remote_identities.oauth_client_id
    SQL

    execute_sql "DELETE FROM remote_identities"
  end
end
