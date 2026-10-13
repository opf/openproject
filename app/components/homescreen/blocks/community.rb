# frozen_string_literal: true

# -- copyright
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
# ++

module Homescreen
  module Blocks
    class Community < Grids::WidgetComponent
      def title
        I18n.t(:"homescreen.blocks.community")
      end

      def wrapper_arguments
        { content_padding: :condensed }
      end

      def links
        [
          { path: :user_guides },
          { path: :shortcuts },
          { path: :forums },
          { path: EnterpriseToken.active? ? :enterprise_support : :enterprise_support_as_community },
          { path: :website,
            label: I18n.t("label_openproject_website"),
            url_params: { utm_source: "unknown", utm_medium: "op-instance", utm_campaign: "website-home-screen" } },
          { path: :security_alerts,
            label: I18n.t("homescreen.links.security_alerts"),
            url_params: { utm_source: "unknown", utm_medium: "op-instance", utm_campaign: "security-alerts-home-screen" } },
          { path: :newsletter,
            label: I18n.t("homescreen.links.newsletter"),
            url_params: { utm_source: "unknown", utm_medium: "op-instance", utm_campaign: "newsletter-home-screen" } },
          { path: :blog },
          { path: :release_notes },
          { path: :report_bug },
          { path: :roadmap },
          { path: :crowdin },
          { path: :api_docs }
        ]
      end

      def link_href(link)
        OpenProject::Static::Links.url_for(link[:path], url_params: link[:url_params] || {})
      end

      def link_label(link)
        link[:label] || OpenProject::Static::Links.label_for(link[:path])
      end
    end
  end
end
