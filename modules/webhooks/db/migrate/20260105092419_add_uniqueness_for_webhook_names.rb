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

class AddUniquenessForWebhookNames < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    execute <<~SQL.squish
      UPDATE webhooks_webhooks SET name = webhooks_webhooks.name || ' ' || counter.rn
      FROM (SELECT id, row_number() OVER (PARTITION BY LOWER(name) ORDER BY id) AS rn FROM webhooks_webhooks) AS counter
      WHERE webhooks_webhooks.id = counter.id AND counter.rn > 1;
    SQL

    add_index :webhooks_webhooks, "LOWER(name)", unique: true, algorithm: :concurrently,
                                                 name: "index_webhooks_webhooks_on_LOWER_name"
  end

  def down
    remove_index :webhooks_webhooks, name: "index_webhooks_webhooks_on_LOWER_name", algorithm: :concurrently
  end
end
