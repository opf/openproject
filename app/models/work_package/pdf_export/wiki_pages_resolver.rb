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

# Resolves the wiki pages an artefact export embeds.
#
# `submitted` arrives from the Generate PDF dialog and is therefore attacker controlled:
# it is filtered down to the pages the type variant configured plus the pages the user may
# read themselves. Configuring a page is the grant, so configured pages are loaded without
# the visibility scope.
module WorkPackage::PDFExport
  class WikiPagesResolver
    def initialize(submitted:, configured:, user: User.current)
      @submitted = submitted
      @configured = configured
      @user = user
    end

    def call
      ordered_refs.filter_map { pages_by_id[it.identifier.to_i] }
    end

    private

    attr_reader :submitted, :configured, :user

    def ordered_refs
      @ordered_refs ||= internal_refs(submitted.nil? ? configured : submitted)
    end

    def configured_ids
      @configured_ids ||= internal_refs(configured).map { it.identifier.to_i }
    end

    def requested_ids
      @requested_ids ||= ordered_refs.map { it.identifier.to_i }
    end

    def internal_refs(values)
      return [] if internal_provider_id.nil?

      WikiPageRef.parse_all(values).select { it.provider_id == internal_provider_id }
    end

    def internal_provider_id
      return @internal_provider_id if defined?(@internal_provider_id)

      @internal_provider_id = ::Wikis::InternalProvider.first&.id&.to_s
    end

    def pages_by_id
      @pages_by_id ||= (granted_pages + visible_pages).select { exportable?(it) }.index_by(&:id)
    end

    def granted_pages
      ids = requested_ids & configured_ids
      return [] if ids.empty?

      WikiPage.includes(:project).where(id: ids).to_a
    end

    def visible_pages
      ids = requested_ids - configured_ids
      return [] if ids.empty?

      WikiPage.visible(user).where(id: ids).to_a
    end

    def exportable?(page)
      page.project.present? && page.project.active?
    end
  end
end
