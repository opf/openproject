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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Backlogs
  module WorkPackages
    class CardsController < Backlogs::BaseController
      before_action :load_work_package

      # Renders the content of a single backlog work package card into its
      # turbo-frame. The frame is loaded lazily by
      # Backlogs::WorkPackageCardListItemLoadingComponent with a +version+ derived
      # from the card's state hash, so each distinct state maps to a distinct URL
      # that the client can cache.
      # Cards are permission scoped, so the cache has to stays private to the browser.
      def show
        # Caveat here: If the user were to lose the permissions to see a work package,
        # they would still have it cached locally, if they ever looked at the card.
        # But the same would be true for every screenshot or PDF export.
        expires_in 1.year, public: false, immutable: true

        render(Backlogs::WorkPackageCardComponent.new(
                 work_package: @work_package,
                 menu_src: menu_project_backlogs_work_package_path(@project, @work_package)
               ),
               layout: false)
      end

      private

      def load_work_package
        @work_package = ::WorkPackage.visible.where(project: @project).find(params.expect(:work_package_id))
      end
    end
  end
end
