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
  module Assistance
    class FindingComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      SEVERITY_SCHEMES = { "high" => :danger, "medium" => :attention, "low" => :secondary }.freeze

      attr_reader :finding

      def initialize(finding:)
        super
        @finding = finding
      end

      def wrapper_key
        "ai-assistance-finding-#{finding.id}"
      end

      def severity_scheme
        SEVERITY_SCHEMES.fetch(finding.severity, :secondary)
      end

      def severity_label
        I18n.t("ai_assistance.severities.#{finding.severity}")
      end

      def area_label
        I18n.t("ai_assistance.areas.#{finding.area}", default: finding.area.to_s.humanize)
      end

      def evidence_href(item)
        if item["work_package_id"]
          url_helpers.work_package_path(item["work_package_id"])
        elsif item["url"].to_s.start_with?("https://", "http://")
          item["url"]
        end
      end

      def evidence_link_arguments(item)
        arguments = { href: evidence_href(item) }
        arguments.merge!(target: "_blank", rel: "noopener noreferrer") if item["work_package_id"].nil?
        arguments
      end

      def text_color
        finding.dismissed? ? :muted : :default
      end

      def dismiss_path(reason = nil)
        url_helpers.dismiss_work_package_ai_assistance_run_finding_path(finding.run.work_package,
                                                                      finding.run,
                                                                      finding,
                                                                      reason:)
      end

      def dismiss_reasons
        AI::AssistantRunFinding.dismiss_reasons.keys
      end
    end
  end
end
