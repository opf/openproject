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

class CreateWebhooksKubernetesTables < ActiveRecord::Migration[8.0]
  def change
    create_table :webhooks_kubernetes_connections do |t|
      t.string :name, null: false
      t.string :auth_mode, null: false, default: "bearer_token"
      t.string :api_url
      t.string :namespace
      t.boolean :verify_tls, null: false, default: true
      t.text :ca_cert
      t.text :token
      t.text :client_cert
      t.text :client_key

      t.timestamps
    end

    create_table :webhooks_kubernetes_scripts do |t|
      t.string :name, null: false
      t.text :description
      t.references :kubernetes_connection, null: false,
                                           foreign_key: { to_table: :webhooks_kubernetes_connections }
      t.string :image, null: false
      t.string :command, null: false
      t.text :body, null: false
      t.string :event_names, array: true, null: false, default: []
      t.integer :timeout_seconds, null: false, default: 300

      t.timestamps
    end

    create_table :webhooks_kubernetes_project_scripts do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.references :kubernetes_script, null: false,
                                       foreign_key: { to_table: :webhooks_kubernetes_scripts, on_delete: :cascade }

      t.timestamps
    end
    add_index :webhooks_kubernetes_project_scripts,
              %i[project_id kubernetes_script_id],
              unique: true,
              name: "index_webhooks_k8s_project_scripts_unique"

    create_table :webhooks_kubernetes_script_runs do |t|
      t.references :kubernetes_script, null: false,
                                       foreign_key: { to_table: :webhooks_kubernetes_scripts, on_delete: :cascade }
      t.references :project, foreign_key: { on_delete: :nullify }
      t.string :event_name, null: false
      t.string :status, null: false, default: "queued"
      t.string :k8s_job_name
      t.text :message

      t.timestamps
    end
  end
end
