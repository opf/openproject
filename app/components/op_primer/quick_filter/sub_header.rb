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

module OpPrimer
  module QuickFilter
    # Primer::OpenProject::SubHeader (gem) knows nothing about the filter--filters-form Stimulus
    # controller; this wrapper is the only place that does. Every data attribute that controller
    # understands is exposed here as a plain keyword argument, so no caller ever spells out a
    # "filter--filters-form-*" string directly.
    #
    # It refuses to render any quick_filters unless query was explicitly provided, so forgetting
    # it fails loudly at render time instead of silently resetting other active quick filters.
    # This does not depend on whether a bottom_pane_component is also present: that pane's DOM
    # only covers filters it renders a row for, which is not guaranteed to include every
    # quick_filter (e.g. a type/project quick_filter next to a name-only advanced filter form).
    class SubHeader < Primer::OpenProject::SubHeader
      CURRENT_FILTERS_DATA_KEY = :"filter--filters-form-current-filters-value"

      def initialize(
        query: nil,
        clear_button_id: nil,
        output_format: nil,
        turbo_frame_request: nil,
        turbo_stream_request: nil,
        url_path_name: nil,
        display_filters: nil,
        reset_params: nil,
        **system_arguments
      )
        @query = query

        data = set_quick_filter_attributes(clear_button_id, output_format, turbo_frame_request, turbo_stream_request,
                                             url_path_name, display_filters, reset_params, query)

        system_arguments[:data] = merge_data(system_arguments, { data: })

        super(**system_arguments)
      end

      private

      def before_render
        super

        return unless quick_filters.present? && !current_filters_attribute_present?

        raise ArgumentError,
              "#{self.class} renders quick_filters without a query. Without it, any filter that " \
              "isn't backed by a registered filter target — including every quick_filter here — " \
              "gets silently dropped the next time a request goes through the " \
              "filter--filters-form controller, e.g. when another quick filter is picked or text " \
              "is typed into a filter_input. Pass query: to prevent that."
      end

      def current_filters_attribute_present?
        @query.present? || @system_arguments.dig(:data, CURRENT_FILTERS_DATA_KEY).present?
      end

      # rubocop:disable-next Metrics/PerceivedComplexity
      def set_quick_filter_attributes(clear_button_id, output_format, turbo_frame_request, turbo_stream_request, url_path_name,
                                      display_filters, reset_params, query)
        data = { controller: "filter--filters-form" }
        data[:"filter--filters-form-clear-button-id-value"] = clear_button_id if clear_button_id
        data[:"filter--filters-form-output-format-value"] = output_format if output_format
        data[:"filter--filters-form-turbo-frame-request-value"] = turbo_frame_request if turbo_frame_request
        data[:"filter--filters-form-turbo-stream-request-value"] = true if turbo_stream_request
        data[:"filter--filters-form-url-path-name-value"] = url_path_name if url_path_name
        data[:"filter--filters-form-display-filters-value"] = true if display_filters
        data[:"filter--filters-form-reset-params-value"] = reset_params.to_json if reset_params
        data[CURRENT_FILTERS_DATA_KEY] = OpPrimer::QuickFilter.serialize(query.filters).to_json if query

        data
      end
    end
  end
end
