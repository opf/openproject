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
  class KubernetesScript < ApplicationRecord
    belongs_to :kubernetes_connection, class_name: "::Webhooks::KubernetesConnection"
    belongs_to :project_role, class_name: "::ProjectRole", optional: true
    belongs_to :global_role, class_name: "::GlobalRole", optional: true
    has_many :project_scripts, class_name: "::Webhooks::KubernetesProjectScript", dependent: :destroy
    has_many :projects, through: :project_scripts
    has_many :runs, class_name: "::Webhooks::KubernetesScriptRun", dependent: :delete_all
    has_one :service_account_association, as: :service, dependent: :destroy
    has_one :service_account, through: :service_account_association
    has_one :oauth_application, class_name: "::Doorkeeper::Application", as: :integration, dependent: :destroy

    validates :name, presence: true, uniqueness: { case_sensitive: false }
    validates :image, :command, :body, presence: true
    validates :timeout_seconds, numericality: { only_integer: true, greater_than: 0 }

    after_create :ensure_api_identity!
    after_update :rename_api_identity, if: :saved_change_to_name?
    before_destroy :lock_service_account, prepend: true
    after_destroy :destroy_roles

    def ensure_api_identity!
      transaction do
        unless service_account
          account = ServiceAccount.create!(name: service_account_name, status: :active)
          create_service_account_association!(service_account: account)
          reload_service_account
        end

        oauth_application || create_oauth_application!(
          name: service_account_name,
          redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
          scopes: "api_v3",
          confidential: true,
          client_credentials_user_id: service_account.id,
          owner: service_account
        )
      end
    end

    def ensure_roles!
      transaction do
        self.project_role ||= ::ProjectRole.create!(name: service_account_name)
        self.global_role ||= ::GlobalRole.create!(name: global_role_name)
        save! if changed?
      end
      { project: project_role, global: global_role }
    end

    def issue_access_token!(project:, expires_in:)
      ensure_api_identity!
      project_script = project_scripts.find_by(project:) or raise "Script is not enabled in project #{project&.id}"
      ::Doorkeeper::AccessToken.create!(
        application: oauth_application,
        resource_owner_id: project_script.ensure_identity!.id,
        scopes: "api_v3",
        expires_in:
      )
    end

    def global_role_name
      I18n.t("webhooks.kubernetes.scripts.global_role_name", name: service_account_name)
    end

    def service_account_name
      I18n.t("webhooks.kubernetes.scripts.service_account_name",
             name: name.to_s.gsub(User::INVALID_NAME_REGEX, " ").squish)
    end

    def self.for_event(event_name, project_id)
      joins(:project_scripts)
        .where(webhooks_kubernetes_project_scripts: { project_id: })
        .where("? = ANY(event_names)", event_name)
    end

    def event_names=(names)
      super(Array(names).compact_blank)
    end

    private

    def rename_api_identity
      service_account&.update!(name: service_account_name)
      oauth_application&.update!(name: service_account_name)
      project_role&.update!(name: service_account_name)
      global_role&.update!(name: global_role_name)
      project_scripts.includes(:project).find_each(&:ensure_identity!)
    end

    def destroy_roles
      ::Role.where(id: [project_role_id, global_role_id].compact).destroy_all
    end

    # The account is kept (locked) so that journals created through the API stay attributed to it.
    def lock_service_account
      service_account&.update_column(:status, User.statuses[:locked])
    end
  end
end
