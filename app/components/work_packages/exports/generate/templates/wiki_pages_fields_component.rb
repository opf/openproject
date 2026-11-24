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
        class WikiPagesFieldsComponent < ApplicationComponent
          include ApplicationHelper
          include OpPrimer::ComponentHelpers

          STIMULUS_CONTROLLER = "work-packages--export--wiki-pages"
          FIELD_NAME = "wiki_pages[]"
          WRAPPER_ID = "op-pdf-export-wiki-pages"
          DIALOG_ID = "op-pdf-export-wiki-pages-dialog"

          Entry = Data.define(:reference, :label)

          attr_reader :refs, :disabled, :context

          def initialize(refs: [], disabled: false, context: :configuration)
            super

            @refs = refs
            @disabled = disabled
            @context = context
          end

          def configuration? = context == :configuration

          def entries
            @entries ||= refs.map { entry_for(it) }
          end

          def selected_options
            entries.map { { id: it.reference, name: it.label } }
          end

          def provider_id
            return @provider_id if defined?(@provider_id)

            @provider_id = ::Wikis::InternalProvider.first&.id
          end

          def add_disabled? = disabled || provider_id.nil?

          def wrapper_data
            {
              controller: STIMULUS_CONTROLLER,
              "#{STIMULUS_CONTROLLER}-provider-id-value": provider_id
            }
          end

          def autocompleter_inputs
            {
              id: "#{WRAPPER_ID}-autocompleter",
              name: FIELD_NAME,
              inputHidden: true,
              autofocus: false,
              options: [],
              selected: selected_options,
              protected: disabled ? selected_options : [],
              dragAreaLabel: I18n.t("pdf_generator.dialog.wiki_pages.manage_label"),
              required: false
            }
          end

          private

          def entry_for(ref)
            page = pages_by_id[ref.identifier.to_i]
            label = if page
                      page_label(page)
                    else
                      I18n.t("pdf_generator.dialog.wiki_pages.unavailable", reference: ref.to_s)
                    end

            Entry.new(reference: ref.to_s, label:)
          end

          def page_label(page) = "#{page.project.name}: #{page.title}"

          # Configured pages are shown to every configurator, so the visibility scope is
          # deliberately not applied here.
          def pages_by_id
            @pages_by_id ||= WikiPage.includes(:project)
                                     .where(id: refs.map { it.identifier.to_i })
                                     .select { it.project&.active? }
                                     .index_by(&:id)
          end
        end
      end
    end
  end
end
