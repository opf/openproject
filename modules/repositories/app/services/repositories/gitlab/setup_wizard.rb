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

module Repositories::Gitlab
  class SetupWizard < ::Wizard
    step :general_information,
         completed_if: ->(provider) { provider.persisted? }

    step :webhook_user,
         section: :webhook,
         completed_if: ->(provider) { provider.webhook_user_configured? }

    step :webhook,
         section: :webhook,
         completed_if: ->(provider) { provider.webhook_secret.present? },
         preparation: :generate_webhook_secret

    private

    def generate_webhook_secret(provider)
      ::Repositories::Providers::UpdateService
        .new(user:, model: provider, contract_class: ::Repositories::GitlabProviders::UpdateContract)
        .call(webhook_secret: provider.class.generate_webhook_secret)
    end
  end
end
