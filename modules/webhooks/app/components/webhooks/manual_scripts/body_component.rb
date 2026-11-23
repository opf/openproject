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

module Webhooks
  module ManualScripts
    class BodyComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      STATUS_SCHEMES = { queued: :secondary, running: :attention, succeeded: :success, failed: :danger,
                         error: :danger }.freeze
      RESULT_MARKER = "::op-result::"
      POLL_INTERVAL_MS = 1000

      def initialize(script:, work_package:, values: nil, errors: {}, run: nil, state: {})
        super
        @state = state
        @script = script
        @work_package = work_package
        @values = values
        @errors = errors
        @run = run
      end

      private

      attr_reader :script, :work_package, :run

      def form_config
        ::JsonForms::InputForm.form_arguments(url: work_package_manual_scripts_path(work_package, script_id: script.id),
                                              refresh_url:)
      end

      def refresh_url
        refresh_work_package_manual_scripts_path(work_package, script_id: script.id)
      end

      def input_form(form)
        schema = script.form_schema.schema
        ::JsonForms::InputForm.new(form, schema:, ui_schema: script.ui_schema,
                                         data: @values || ::JsonForms::FormData.apply_defaults(schema, {}),
                                         errors: @errors, context: { work_package:, overlay_id: dialog_id }, refresh_url:,
                                         state: @state)
      end

      def dialog_id
        DialogComponent::DIALOG_ID
      end

      def run_active?
        run.queued? || run.running?
      end

      def poll_data
        return {} unless run_active?

        {
          controller: "poll-for-changes",
          poll_for_changes_url_value: work_package_manual_script_path(work_package, run),
          poll_for_changes_interval_value: POLL_INTERVAL_MS,
          poll_for_changes_reference_value: run.status
        }
      end

      def result
        return @result if defined?(@result)

        line = run.message.to_s.lines.rfind { it.start_with?(RESULT_MARKER) }
        @result = line && JSON.parse(line.delete_prefix(RESULT_MARKER)).then { it.is_a?(Hash) ? it : nil }
      rescue JSON::ParserError
        @result = nil
      end

      def output
        run.message.to_s.lines.reject { it.start_with?(RESULT_MARKER) }.join.strip
      end

      def status_scheme
        STATUS_SCHEMES.fetch(run.status.to_sym, :secondary)
      end
    end
  end
end
