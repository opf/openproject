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

module Admin::Import::Jira::ImportRuns
  class FinalizeConfirmDialogComponent < ApplicationComponent
    include OpTurbo::Streamable

    def initialize(jira_import:)
      super
      @jira_import = jira_import
    end

    def id = "finalize-jira-import-run-dialog"

    def form_arguments
      {
        action: url,
        method: :post
      }
    end

    def title
      I18n.t("admin.jira.run.wizard.finalize_dialog.title")
    end

    def description
      I18n.t("admin.jira.run.wizard.finalize_dialog.description")
    end

    def confirm_button_text
      I18n.t("admin.jira.run.wizard.finalize_dialog.confirm_button")
    end

    def confirm
      I18n.t("admin.jira.run.wizard.finalize_dialog.confirm")
    end

    private

    def url
      continue_admin_import_jira_run_path(jira_id: @jira_import.jira.id, id: @jira_import.id, step: "finalize")
    end
  end
end
