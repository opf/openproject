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

module Projects::Settings::WorkPackages::Types::Variants
  # The workflow matrix editor, re-homed inside a project's settings. The parent resolves its
  # variant lazily through #variant rather than in a callback, so there is nothing to
  # re-register — only the authorization to swap and the lookup to narrow.
  class MatrixController < ::Workflows::MatrixController
    include ::WorkPackageTypes::TypeVariantsFeature

    menu_item :settings_work_packages

    skip_before_action :require_admin

    before_action :find_project_by_project_id
    before_action :authorize
    before_action :require_type_variants_feature

    private

    # A variant of another project is absent rather than forbidden.
    def variant
      @variant ||= begin
        found = ::TypeVariant.non_default_variants
                             .owned_by(@project)
                             .find_by(id: params[:variant_id], type_id: params[:type_id])
        render_404 if found.nil?
        found
      end
    end
  end
end
