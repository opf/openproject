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

module OpenProject
  module TextFormatting
    # Maps a high-level rendering channel (`:in_app_html`, `:external_html`,
    # `:external_text`) onto the primitive `only_path` / `static_html` /
    # `plain_text` context flags that the filter pipeline reads.
    #
    # External surfaces always need absolute URLs *and* static rendering for
    # JS-dependent components — the two flags are a coupled set. A single
    # mode value is the canonical API; the primitives stay available as
    # per-flag escape hatches for callers that need an asymmetric mix.
    module RenderMode
      DEFAULTS = {
        in_app_html: { only_path: true, static_html: false, plain_text: false }.freeze,
        external_html: { only_path: false, static_html: true, plain_text: false }.freeze,
        external_text: { only_path: false, static_html: false, plain_text: true }.freeze
      }.freeze

      module_function

      def resolve(mode, only_path: nil, static_html: nil, plain_text: nil)
        defaults = DEFAULTS.fetch(mode) do
          raise ArgumentError, "Unknown render_mode: #{mode.inspect}. " \
                               "Expected one of #{DEFAULTS.keys.inspect}."
        end

        {
          only_path: only_path.nil? ? defaults[:only_path] : only_path,
          static_html: static_html.nil? ? defaults[:static_html] : static_html,
          plain_text: plain_text.nil? ? defaults[:plain_text] : plain_text
        }
      end
    end
  end
end
