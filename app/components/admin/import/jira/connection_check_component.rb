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

module Admin::Import::Jira
  class ConnectionCheckComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers
    include OpTurbo::Streamable

    alias_method :jira, :model

    def initialize(jira, report: jira.latest_health_report)
      super(jira)
      @report = report
    end

    private

    attr_reader :report

    def report_state
      if report.nil?
        I18n.t("admin.jira.connection_check.not_checked")
      elsif report.new_record?
        I18n.t("admin.jira.connection_check.form_values_checked")
      else
        I18n.t("admin.jira.connection_check.last_check", datetime: helpers.format_time(report.created_at))
      end
    end

    def test_connection_button_arguments
      {
        type: :submit,
        form: FormComponent::FORM_ID,
        formaction: test_connection_path,
        formnovalidate: true,
        data: { turbo_submits_with: I18n.t("admin.jira.form.label_testing") }
      }
    end

    def test_connection_path
      if jira.persisted?
        test_connection_admin_import_jira_path(jira)
      else
        test_connection_admin_import_jira_index_path
      end
    end
  end
end
