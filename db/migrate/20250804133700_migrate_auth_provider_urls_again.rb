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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class MigrateAuthProviderUrlsAgain < ActiveRecord::Migration[8.0]
  def change # rubocop:disable Metrics/AbcSize
    reversible do |direction|
      direction.up do
        PluginAuthProvider.create_all_registered

        users_data = execute(<<-SQL.squish).values
          SELECT id, identity_url FROM users WHERE type = 'User' AND NOT (identity_url = '' OR identity_url IS NULL);
        SQL
        auth_providers_data = execute(<<-SQL.squish).values
          SELECT id, slug FROM auth_providers
        SQL

        insert_data = users_data.filter_map do |user_id, identity_url|
          slug, external_id = identity_url.split(":", 2)
          next if slug.blank? || external_id.blank?

          auth_provider_id, = auth_providers_data.find { |_, auth_provider_slug| auth_provider_slug == slug }
          next if auth_provider_id.blank?

          "(#{user_id}, #{auth_provider_id}, '#{external_id}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
        end.join(",\n")

        if insert_data.present?
          execute(<<-SQL.squish).values
            INSERT INTO user_auth_provider_links (user_id, auth_provider_id, external_id, created_at, updated_at)
              VALUES #{insert_data}
              ON CONFLICT DO NOTHING
              RETURNING id
          SQL
        end
      end
    end
  end
end
