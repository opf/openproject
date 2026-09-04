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
  class BacklogFiltersComponent < Filter::FilterComponent
    # Controlled by their own dedicated pickers (sprint/bucket/inbox/project selects),
    # so they don't belong in the generic advanced filter panel.
    PICKER_CONTROLLED_FILTER_NAMES = %i[sprint_id backlog_bucket_id backlog_inbox project_id].freeze
    # Has its own permanent quick-search input in the subheader, so it doesn't belong
    # in the generic advanced filter panel either, but unlike the picker-controlled
    # ones above, it still counts as a filter the user applied (see
    # Backlogs::BacklogFilterButtonComponent#filters_count).
    QUICK_SEARCH_FILTER_NAME = :subject

    EXCLUDED_FILTER_NAMES = (PICKER_CONTROLLED_FILTER_NAMES + [QUICK_SEARCH_FILTER_NAME]).freeze

    options excluded_filters: EXCLUDED_FILTER_NAMES

    def allowed_filters
      super.sort_by(&:human_name)
    end

    def turbo_requests? = true
  end
end
