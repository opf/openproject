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
  # A backlog list row that lazily loads its work package card through a
  # turbo-frame instead of rendering the card inline.
  #
  # The frame's +src+ carries a +version+ derived from the card's state hash
  # (see WorkPackages::Scopes::WithCardHash). As long as that hash is stable the
  # client keeps the cached card; a changed hash points the frame at a fresh URL
  # which is served by Backlogs::WorkPackages::CardsController.
  #
  # Row behaviour (dragging, selection, urls) is inherited from
  # WorkPackageCardListItemComponent; only the rendered content differs.
  class WorkPackageCardListItemLoadingComponent < WorkPackageCardListItemComponent
    def call
      helpers.turbo_frame_tag(WorkPackageCardComponent.frame_id(work_package),
                              loading: :lazy,
                              src: card_src) do
        render(Primer::Alpha::SkeletonBox.new(width: "100%", height: "40px"))
      end
    end

    private

    def card_src
      url_helpers.project_backlogs_work_package_card_path(project, work_package, version: work_package.card_hash)
    end
  end
end
