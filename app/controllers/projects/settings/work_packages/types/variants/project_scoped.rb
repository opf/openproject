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
  # Re-homes the administration configuration tabs inside a project's settings. The tab bodies
  # are the administration ones untouched; what changes is who may reach them and which
  # variants they can name at all.
  #
  # The inherited lookups are dropped and re-registered rather than prepended: the project
  # lookup reads Project.visible and #authorize reads the current user, both of which need
  # ApplicationController's user_setup to have run first. Prepending them ahead of it leaves
  # User.current anonymous and redirects every request to the login page — and no request spec
  # can see that, because login_as stubs RequestStore[:current_user], which is exactly what
  # user_setup would have filled in.
  module ProjectScoped
    extend ActiveSupport::Concern
    include ::WorkPackageTypes::TypeVariantsFeature

    included do
      # The tabs are inherited from administration, whose layout renders its menu. Inside a
      # project the surrounding chrome is the project's own.
      layout "base"

      menu_item :settings_work_packages

      skip_before_action :require_admin
    end

    private

    # Both lookups keep the positions they are inherited at, and the project resolution and
    # authorization ride along with the first of them rather than being appended as callbacks
    # of their own. Two things have to hold at once, and only this position satisfies both:
    #
    # - they must run after ApplicationController#user_setup, or User.current is anonymous,
    #   Project.visible finds nothing, and every request redirects to the login page;
    # - they must run before any callback a tab controller adds itself — DetailsTabController's
    #   set_editable, for one — because those read @type and @variant.
    #
    # An appended before_action satisfies the first and breaks the second.
    def find_type
      find_project_by_project_id
      return if performed?

      authorize
      return if performed?

      require_type_variants_feature
      return if performed?

      @type = ::Type.find(params.expect(:type_id))
    end

    # A variant of another project is absent rather than forbidden, so a project administrator
    # cannot tell the two apart by probing ids.
    def find_variant
      return if performed?

      @variant = @type.variants.non_default_variants.owned_by(@project).find_by(id: params[:variant_id])

      render_404 if @variant.nil?
    end
  end
end
