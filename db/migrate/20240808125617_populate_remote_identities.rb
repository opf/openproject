#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

class PopulateRemoteIdentities < ActiveRecord::Migration[7.1]
  def up
    fields = %i[user_id oauth_client_id origin_user_id]

    OAuthClientToken.where.not(origin_user_id: nil)
                    .select(:id, *fields)
                    .find_in_batches do |batch|
      identities = batch.map { |record| record.slice(*fields) }

      RemoteIdentity.insert_all(identities, unique_by: %i[user_id oauth_client_id])
    end

    OAuthClientToken.update_all(origin_user_id: nil)
  end

  def down
    RemoteIdentity.find_in_batches do |batch|
      batch.each do |identity|
        OAuthClientToken
          .where(user: identity.user, oauth_client: identity.oauth_client)
          .update_all(origin_user_id: identity.origin_user_id)
      end
    end

    RemoteIdentity.delete_all
  end
end
