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
  Registry = Dry::Core::Container::Namespace.new("gitlab") do
    register(:provider, Repositories::GitlabProvider)

    namespace("components") do
      register(:setup_wizard, SetupWizard)

      register(:general_information, Repositories::Admin::GeneralInfoComponent)
      register(:webhook_user, Repositories::Admin::WebhookUserInfoComponent)
      register(:webhook, Repositories::Admin::WebhookInfoComponent)

      namespace("forms") do
        register(:general_information, Repositories::Admin::Forms::GeneralInfoFormComponent)
        register(:webhook_user, Repositories::Admin::Forms::WebhookUserFormComponent)
        register(:webhook, Repositories::Admin::Forms::WebhookFormComponent)
      end
    end

    namespace("contracts") do
      register(:create, Repositories::GitlabProviders::CreateContract)
      register(:update, Repositories::GitlabProviders::UpdateContract)
    end
  end
end
