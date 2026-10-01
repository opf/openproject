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

module WorkPackage::Exports
  module Macros
    class WorkPackagesLinkHandler < OpenProject::TextFormatting::Matchers::LinkHandlers::WorkPackages
      def applicable?
        return false unless hash_trigger? && matcher.prefix.blank?

        if WorkPackage::SemanticIdentifier.numeric_id?(matcher.identifier)
          true
        elsif WorkPackage::SemanticIdentifier.semantic_id?(matcher.identifier)
          Setting::WorkPackageIdentifier.semantic?
        else
          false
        end
      end

      # PDF rendering walks Markly nodes directly rather than the in-app
      # preload pipeline, so each semantic reference does its own round-trip.
      # Resolution is visibility-scoped: a reference to a work package the
      # current user cannot see falls through to literal text, identical to
      # an unknown identifier, so semantic ids cannot act as an existence
      # oracle.
      def call
        if WorkPackage::SemanticIdentifier.semantic_id?(matcher.identifier)
          wp = WorkPackage.visible.find_by_display_id(matcher.identifier)
          return nil unless wp

          render_link(wp.display_id, matcher)
        else
          render_link(matcher.identifier, matcher)
        end
      end

      def render_link(data_id, matcher)
        link = "#{matcher.sep}#{data_id}"
        content_tag(:mention, link,
                    class: "mention",
                    data: { id: data_id, type: "work_package", text: link })
      end
    end

    class Links < OpenProject::TextFormatting::Matchers::ResourceLinksMatcher
      def self.link_handlers
        [WorkPackagesLinkHandler]
      end

      # Faster inclusion check before the full regex is being applied.
      # Matches `#1`, `##42`, `#PROJ-7` openings — semantic-only bodies
      # must reach the regex too.
      def self.applicable?(content)
        /#[A-Z\d]/.match(content)
      end
    end
  end
end
