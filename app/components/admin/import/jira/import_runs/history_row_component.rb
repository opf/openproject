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
  class HistoryRowComponent < OpPrimer::BorderBoxRowComponent
    def button_links
      []
    end

    def from_to
      render(Primer::OpenProject::FlexLayout.new) do |c|
        c.with_column do
          render(StatusBadgeComponent.new(model.from_state))
        end
        c.with_column do
          render(Primer::Beta::Octicon.new(:"arrow-right", size: :small))
        end
        c.with_column do
          render(StatusBadgeComponent.new(model.to_state))
        end
      end
    end

    delegate :created_at, to: :model

    def metadata
      render(Primer::OpenProject::FlexLayout.new) do |component|
        component.with_row(p: 1) { model.created_at.to_s }
        user_row(component)
        if good_job_dashboard_enabled?
          job_row(component)
          batch_row(component)
        end
        error_rows(component)
      end
    end

    private

    def good_job_dashboard_enabled?
      Rails.application.routes.url_helpers.respond_to?(:good_job_path)
    end

    def gj_url_helpers
      GoodJob::Engine.routes.url_helpers
    end

    def user_row(component)
      return unless (user_id = model.metadata["user_id"])

      user = User.find_by(id: user_id)
      component.with_row(p: 1) do
        user.present? ? "User #{user}" : "User with id #{user_id} not found"
      end
    end

    def job_row(component)
      return unless (job_id = model.metadata["job_id"])

      component.with_row(bg: :attention, p: 1) do
        render(Primer::Beta::Link.new(href: gj_url_helpers.job_path(id: job_id), target: "_blank")) { "Job" }
      end
    end

    def batch_row(component)
      return unless (batch_id = model.metadata["batch_id"])

      component.with_row(bg: :attention, p: 1) do
        render(Primer::Beta::Link.new(href: gj_url_helpers.batch_path(id: batch_id), target: "_blank")) { "Batch" }
      end
    end

    def error_rows(component)
      if (error = model.metadata["error"])
        component.with_row(bg: :danger, p: 1) { error }
      end
      if error_backtrace = model.metadata["error_backtrace"]
        component.with_row(bg: :danger, p: 2) do
          render(OpPrimer::ExpandableTextComponent.new(expansion: :dialog)) do |component|
            component.with_dialog(title: t(:label_backtrace), size: :xlarge) do |dialog|
              dialog.with_header(variant: :large)
              dialog.with_body_content(error_backtrace.inspect)
            end

            error_backtrace.inspect
          end
        end
      end
    end
  end
end
