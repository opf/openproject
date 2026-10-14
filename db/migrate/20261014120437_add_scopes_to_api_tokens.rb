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

class AddScopesToAPITokens < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE tokens
      SET data = (
        COALESCE(tokens.data::jsonb, '{}'::jsonb) ||
        jsonb_build_object(
          'scopes',
          CASE
            WHEN users.admin THEN '["api_v3", "mcp", "webhooks", "admin_elevation"]'::jsonb
            ELSE '["api_v3", "mcp", "webhooks"]'::jsonb
          END
        )
      )::json
      FROM users
      WHERE tokens.user_id = users.id
        AND tokens.type = 'Token::API'
    SQL
  end

  def down
    execute <<~SQL.squish
      UPDATE tokens
      SET data = (tokens.data::jsonb - 'scopes')::json
      WHERE tokens.type = 'Token::API'
        AND tokens.data IS NOT NULL
    SQL
  end
end
