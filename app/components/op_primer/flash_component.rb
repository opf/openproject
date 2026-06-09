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

      apply_accessibility_defaults(system_arguments)

      super
    end

    def render_as_turbo_stream(...)
      return unless render?

      super
    end

    def live_region_message
      # Preserve word boundaries for line breaks before stripping HTML.
      strip_tags(trimmed_content.to_s.gsub(%r{<br\s*/?>}i, " ")).squish
    end

    def live_region_politeness
      urgent? ? "assertive" : "polite"
    end

    private

    def apply_accessibility_defaults(system_arguments)
      system_arguments.reverse_merge!(
        test_selector: "op-primer-flash-message",
        dismiss_scheme: :remove,
        dismiss_label: I18n.t(:button_close),
        role: aria_role
      )
      system_arguments[:aria] = { live: live_region_politeness }.merge(system_arguments[:aria] || {})
      apply_flash_data_attributes(system_arguments[:data] ||= {})
    end

    def apply_flash_data_attributes(data)
      data.merge!(
        "flash-target" => "flash",
        "flash-role" => aria_role,
        "autohide" => @autohide
      )
    end

    def render?
      trimmed_content.present?
    end

    def aria_role
      urgent? ? "alert" : "status"
    end

    def success?
      @scheme == :success
    end

    def urgent?
      @scheme == :danger
    end
  end
end
