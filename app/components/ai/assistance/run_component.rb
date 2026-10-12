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
    class RunComponent < ApplicationComponent
      include OpTurbo::Streamable
      include Polling

      attr_reader :run

      def initialize(run:)
        super
        @run = run
      end

      def wrapper_key
        "ai-assistance-run-#{run.id}"
      end

      def findings
        @findings ||= run.findings.by_severity.to_a
      end

      def not_checked
        run.not_checked.map do |entry|
          I18n.t("ai_assistance.not_checked.#{entry['reason']}",
                 default: I18n.t("ai_assistance.not_checked.default", area: entry["area"]))
        end
      end

      def wrapper_data
        run.ai_running? ? poll_data(url_helpers.poll_work_package_ai_assistance_run_path(run.work_package, run)) : {}
      end

      def started_at
        helpers.format_time(run.created_at)
      end
    end
  end
end
