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

module Webhooks
  module Kubernetes
    class ScriptsController < ::ApplicationController
      layout "admin"

      before_action :require_admin
      before_action :find_script, only: %i[edit update destroy permissions update_permissions]

      helper ::RolesHelper

      EXAMPLE_INPUT_SCHEMA = {
        "type" => "object",
        "required" => ["reason"],
        "properties" => {
          "reason" => { "type" => "string", "title" => "Reason", "format" => "textarea" },
          "priority" => {
            "type" => "string", "title" => "Priority", "default" => "normal",
            "oneOf" => [{ "const" => "low", "title" => "Low" }, { "const" => "normal", "title" => "Normal" },
                        { "const" => "high", "title" => "High" }]
          },
          "notify" => { "type" => "boolean", "title" => "Notify the assignee", "default" => true }
        }
      }.freeze

      menu_item :plugin_webhooks_kubernetes_scripts

      def index
        @scripts = ::Webhooks::KubernetesScript.includes(:kubernetes_connection).order(:name)
      end

      def new
        @script = ::Webhooks::KubernetesScript.new(
          image: "python:3.13-slim",
          command: "python",
          body: default_body,
          input_schema: EXAMPLE_INPUT_SCHEMA
        )
      end

      def edit; end

      def create
        @script = ::Webhooks::KubernetesScript.new(permitted_params)
        if @script.save
          flash[:notice] = I18n.t(:notice_successful_create)
          redirect_to admin_kubernetes_scripts_path
        else
          render action: :new, status: :unprocessable_entity
        end
      end

      def update
        if @script.update(permitted_params)
          flash[:notice] = I18n.t(:notice_successful_update)
          redirect_to admin_kubernetes_scripts_path
        else
          render action: :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @script.destroy!
        flash[:notice] = I18n.t(:notice_successful_delete)
        redirect_to admin_kubernetes_scripts_path, status: :see_other
      end

      def permissions
        @roles = @script.ensure_roles!
      end

      def update_permissions
        roles = @script.ensure_roles!
        requested = with_dependencies(Array(params.dig(:role, :permissions)).compact_blank.map(&:to_sym))

        roles[:global].permissions = requested & assignable_permission_names(roles[:global])
        roles[:project].permissions = requested & assignable_permission_names(roles[:project])

        added = requested - Array(params.dig(:role, :permissions)).map(&:to_sym)
        flash[:notice] = [I18n.t(:notice_successful_update), dependency_notice(added)].compact.join(" ")
        redirect_to permissions_admin_kubernetes_script_path(@script), status: :see_other
      end

      private

      def assignable_permission_names(role)
        ::Roles::BaseContract.new(role, current_user).assignable_permissions.map(&:name)
      end

      def with_dependencies(names)
        result = names.uniq
        queue = result.dup
        while (name = queue.shift)
          Array(::OpenProject::AccessControl.permission(name)&.dependencies).each do |dependency|
            next if result.include?(dependency)

            result << dependency
            queue << dependency
          end
        end
        result
      end

      def dependency_notice(added)
        return if added.empty?

        I18n.t("webhooks.kubernetes.scripts.permissions.dependencies_added",
               permissions: added.map { I18n.t(:"permission_#{it}") }.join(", "))
      end

      def find_script
        @script = ::Webhooks::KubernetesScript.find(params.expect(:id))
      end

      def permitted_params
        params
          .expect(kubernetes_script: [:name, :description, :kubernetes_connection_id, :image, :command, :body,
                                      :timeout_seconds, :manual, :button_label, :input_schema, :ui_schema,
                                      { event_names: [], type_ids: [], environment_variable_rows: [%i[name value]] }])
          .with_defaults(event_names: [], type_ids: [], environment_variable_rows: [])
      end

      def default_body
        <<~'PYTHON'
          import json
          import os
          import ssl
          import urllib.request

          with open(os.environ["OP_PAYLOAD_FILE"]) as f:
              payload = json.load(f)

          print(f"Event {os.environ['OP_EVENT']} in project {os.environ['OP_PROJECT_ID']}")

          resource_key = next(key for key in payload if key not in ("action", "actor"))
          resource = payload[resource_key]
          title = resource.get("subject") or resource.get("name") or ""
          print(f"{resource_key} #{resource.get('id')}: {title}")

          if "actor" in payload:
              print(f"Triggered by {payload['actor']['name']}")

          print(f"Payload keys: {', '.join(resource.keys())}")

          with open(os.environ["OP_API_TOKEN_FILE"]) as f:
              token = f.read().strip()

          context = ssl.create_default_context(cafile=os.environ.get("OP_CA_FILE"))
          request = urllib.request.Request(
              f"{os.environ['OP_API_URL']}/api/v3",
              headers={"Authorization": f"Bearer {token}"},
          )
          with urllib.request.urlopen(request, context=context) as response:
              root = json.load(response)

          print(f"API call as: {root['_links']['user']['title']}")
        PYTHON
      end
    end
  end
end
