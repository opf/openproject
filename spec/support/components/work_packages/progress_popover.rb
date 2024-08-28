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

# require_relative "../../toasts/expectations"

module Components
  module WorkPackages
    class ProgressPopover
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers
      # include Toasts::Expectations

      JS_FIELD_NAME_MAP = {
        estimated_time: :estimatedTime,
        percent_complete: :percentageDone,
        percentage_done: :percentageDone,
        remaining_work: :remainingTime,
        remaining_time: :remainingTime,
        status: :statusWithinProgressModal,
        status_within_progress_modal: :statusWithinProgressModal,
        work: :estimatedTime
      }.freeze

      WORK_PACKAGE_FIELD_NAME_MAP = {
        estimated_time: :estimated_hours,
        percent_complete: :done_ratio,
        percentage_done: :done_ratio,
        remaining_work: :remaining_hours,
        remaining_time: :remaining_hours,
        work: :estimated_hours
      }.freeze

      attr_reader :container, :create_form

      def initialize(container: page, create_form: false)
        @container = container
        @create_form = create_form
      end

      def open
        open_by_clicking_on_field(:work)
      end

      def open_by_clicking_on_field(field_name)
        field(field_name).activate!
        wait_for_network_idle # Wait for initial loading to be ready
      end

      def close
        field(:work).close!
      end

      def save
        field(:work).submit_by_clicking_save
      end

      def focus(field_name)
        field(field_name).focus
      end

      def set_value(field_name, value)
        focus(field_name)
        field(field_name).set_value(value)
      end

      def set_values(**field_value_pairs)
        field_value_pairs.each do |field_name, value|
          set_value(field_name, value)
        end
        wait_for_network_idle # Wait for live-update to finish
      end

      def expect_cursor_at_end_of_input(field_name)
        field(field_name).expect_cursor_at_end_of_input
      end

      def expect_disabled(field_name)
        field(field_name).expect_modal_field_disabled
      end

      def expect_focused(field_name)
        field(field_name).expect_modal_field_in_focus
      end

      def expect_read_only(field_name)
        field(field_name).expect_read_only_modal_field
      end

      def expect_select_with_options(field_name, *options)
        field(field_name).expect_select_field_with_options(*options)
      end

      def expect_select_without_options(field_name, *options)
        field(field_name).expect_select_field_with_no_options(*options)
      end

      def expect_value(field_name, value, **properties)
        field(field_name).expect_modal_field_value(value, **properties)
      end

      def expect_values(**field_value_pairs)
        aggregate_failures("progress popover values expectations") do
          field_value_pairs.each do |field_name, value|
            expect_value(field_name, value)
          end
        end
      end

      def expect_hint(field_name, hint)
        expected_caption = hint && I18n.t("work_package.progress.derivation_hints.#{wp_field_name(field_name)}.#{hint}")
        field(field_name).expect_caption(expected_caption)
      end

      def expect_hints(**field_hint_pairs)
        aggregate_failures("progress popover hints expectations") do
          field_hint_pairs.each do |field_name, hint|
            expect_hint(field_name, hint)
          end
        end
      end

      private

      def field(field_name)
        field_name = js_field_name(field_name)
        ProgressEditField.new(container, field_name, create_form:)
      end

      def js_field_name(field_name)
        field_name = field_name.to_s.underscore.to_sym
        JS_FIELD_NAME_MAP.fetch(field_name) do
          raise ArgumentError, "cannot map '#{field_name.inspect}' to its javascript field name"
        end
      end

      def wp_field_name(field_name)
        field_name = field_name.to_s.underscore.to_sym
        WORK_PACKAGE_FIELD_NAME_MAP.fetch(field_name) do
          raise ArgumentError, "cannot map '#{field_name.inspect}' to its work package field name"
        end
      end
    end
  end
end
