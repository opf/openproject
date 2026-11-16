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
  class KubernetesProjectScript < ApplicationRecord
    belongs_to :project, class_name: "::Project"
    belongs_to :kubernetes_script, class_name: "::Webhooks::KubernetesScript"
    has_one :service_account_association, as: :service, dependent: :destroy
    has_one :service_account, through: :service_account_association

    after_create :ensure_identity!
    before_destroy :retire_identity, prepend: true

    def ensure_identity!
      transaction do
        if service_account
          service_account.update!(name: account_name) if service_account.name != account_name
        else
          account = ServiceAccount.create!(name: account_name, status: :active)
          create_service_account_association!(service_account: account)
          reload_service_account
        end

        roles = kubernetes_script.ensure_roles!
        assign_role(project, roles.fetch(:project))
        assign_role(nil, roles.fetch(:global))
      end
      service_account
    end

    def account_name
      I18n.t("webhooks.kubernetes.scripts.project_service_account_name",
             name: kubernetes_script.name, project: project.name)
        .gsub(User::INVALID_NAME_REGEX, " ").squish
    end

    private

    def assign_role(project, role)
      member = Member.find_or_initialize_by(principal: service_account, project:, entity: nil)
      return if member.persisted? && member.roles.include?(role)

      member.member_roles.build(role:)
      member.save!
    end

    # The account is kept (locked) so that journals created through the API stay attributed to it.
    def retire_identity
      return unless service_account

      Member.where(principal: service_account).destroy_all
      service_account.update_column(:status, User.statuses[:locked])
    end
  end
end
