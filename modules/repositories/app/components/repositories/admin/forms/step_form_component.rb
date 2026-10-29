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

module Repositories::Admin::Forms
  class StepFormComponent < Repositories::Admin::ProviderComponent
    options in_wizard: false

    def self.attributes = []

    def form_url
      if provider.persisted?
        query = { step: self.class.step_name }
        query[:continue_wizard] = provider.id if in_wizard
        url_helpers.admin_settings_repository_provider_path(provider, query)
      else
        url_helpers.admin_settings_repository_providers_path(provider_type: provider.to_s)
      end
    end

    def form_method = provider.persisted? ? :patch : :post

    def title = t("repositories.admin.steps.#{self.class.step_name}.title")

    def submit_or_cancel_form(form, **)
      Repositories::Admin::SubmitOrCancelForm.new(form, provider:, in_wizard:, **)
    end
  end
end
