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
module OpPrimer
  class FlashComponent < Primer::Alpha::Banner
    include ApplicationHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    def initialize(**system_arguments)
      @unique_key = system_arguments.delete(:unique_key)
      @scheme = system_arguments[:scheme]&.to_sym
      @autohide = success? && system_arguments[:dismiss_scheme] != :none
      @description = system_arguments[:description]

      apply_accessibility_defaults(system_arguments)

      super
    end

    def render_as_turbo_stream(...)
      return unless render?

      super
    end

    def live_region_message
      # Join text nodes with spaces so formatting elements do not concatenate words.
      [trimmed_content, @description]
        .compact_blank
        .flat_map { |content| Nokogiri::HTML5.fragment(content.to_s).xpath(".//text()").map(&:text) }
        .join(" ")
        .squish
    end

    def live_region_politeness
      urgent? ? "assertive" : "polite"
    end

    private

    def apply_accessibility_defaults(system_arguments)
      system_arguments.reverse_merge!(
        test_selector: "op-primer-flash-message",
        dismiss_scheme: :remove,
        dismiss_label: I18n.t(:button_close)
      )
      # Live region announcements are handled by the controller via @primer/live-region-element
      # to avoid duplicate announcements from the visible banner and the global live region.
      system_arguments[:data] = merge_data(
        system_arguments,
        data: { "flash-target" => "flash", autohide: @autohide }
      )
    end

    def render?
      trimmed_content.present?
    end

    def success?
      @scheme == :success
    end

    def urgent?
      @scheme == :danger
    end
  end
end
