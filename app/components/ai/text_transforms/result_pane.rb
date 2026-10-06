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

module AI
  module TextTransforms
    # Demo only (AI-126): picks the result pane variant to compare. `?ai_pane=panel` or
    # `?ai_pane=overlay` on any page switches it and the choice sticks for the session.
    module ResultPane
      VARIANTS = {
        "overlay" => "AI::TextTransforms::ResultOverlayComponent",
        "panel" => "AI::TextTransforms::ResultPanelComponent"
      }.freeze

      def self.component_for(params:, session:)
        requested = params[:ai_pane].to_s
        session[:ai_pane] = requested if VARIANTS.key?(requested)

        VARIANTS.fetch(session[:ai_pane].to_s, VARIANTS["overlay"]).constantize.new
      end
    end
  end
end
