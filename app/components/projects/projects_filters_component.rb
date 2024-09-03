# frozen_string_literal: true

# -- copyright
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
# ++

# rubocop:disable OpenProject/AddPreviewForViewComponent
class Projects::ProjectsFiltersComponent < Filter::FilterComponent
  # rubocop:enable OpenProject/AddPreviewForViewComponent
  def allowed_filters
    super
      .select { |f| allowed_filter?(f) }
      .sort_by(&:human_name)
  end

  def turbo_requests?
    true
  end

  private

  def allowed_filter?(filter)
    allowlist = [
      Queries::Filters::Shared::CustomFields::Base,
      Queries::Projects::Filters::ActiveFilter,
      Queries::Projects::Filters::CreatedAtFilter,
      Queries::Projects::Filters::FavoredFilter,
      Queries::Projects::Filters::IdFilter,
      Queries::Projects::Filters::LatestActivityAtFilter,
      Queries::Projects::Filters::MemberOfFilter,
      Queries::Projects::Filters::NameAndIdentifierFilter,
      Queries::Projects::Filters::ProjectStatusFilter,
      Queries::Projects::Filters::PublicFilter,
      Queries::Projects::Filters::TemplatedFilter,
      Queries::Projects::Filters::TypeFilter
    ]

    allowlist.any? { |clazz| filter.is_a? clazz }
  end
end
