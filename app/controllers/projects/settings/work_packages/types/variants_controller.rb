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
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects::Settings::WorkPackages::Types
  class VariantsController < ::WorkPackageTypes::VariantsController
    include ::WorkPackageTypes::TypeVariantsFeature

    menu_item :settings_work_packages

    skip_before_action :require_admin
    skip_before_action :find_type, raise: false

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :require_type_variants_feature
    before_action :find_type

    def destroy
      service_call = ::WorkPackageTypes::DeleteVariantService.new(user: current_user, model: named_variant).call

      redirect_to project_settings_work_packages_types_path(@project),
                  status: :see_other,
                  **destroy_flash(service_call)
    end

    private

    def destroy_flash(service_call)
      return { notice: t(:notice_successful_delete) } if service_call.success?

      { alert: service_call.errors.full_messages.to_sentence }
    end

    # Only the project's own variants are addressable, so another project's is a 404 rather
    # than a refusal.
    def named_variant
      @named_variant ||= @type.variants.non_default_variants.owned_by(@project).find(params.expect(:id))
    end
  end
end
