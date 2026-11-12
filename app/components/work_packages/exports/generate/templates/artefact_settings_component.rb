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

module WorkPackages
  module Exports
    module Generate
      module Templates
        class ArtefactSettingsComponent < BaseSettingsComponent
          TEMPLATE_ID = "artefact"

          def self.fields
            %w[toc include_lifecycle include_budget hyphenation hyphenation_language wiki_pages]
          end

          def self.array_fields = %w[wiki_pages]

          attr_reader :context

          def initialize(context: :configuration, **)
            super(**)

            @context = context
          end

          def wiki_page_refs
            WorkPackage::PDFExport::WikiPageRef.parse_all(settings[:wiki_pages])
          end

          def toc
            boolean_setting(:toc, WorkPackage::PDFExport::Artefact::DEFAULT_TOC)
          end

          def include_lifecycle
            boolean_setting(:include_lifecycle, WorkPackage::PDFExport::Artefact::DEFAULT_INCLUDE_LIFECYCLE)
          end

          def include_budget
            boolean_setting(:include_budget, WorkPackage::PDFExport::Artefact::DEFAULT_INCLUDE_BUDGET)
          end
        end
      end
    end
  end
end
