# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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

class Admin::Settings::GithubIntegrationSettingsForm < ApplicationForm
  # TODO: Recheck which GH actions we support and how they are mapped potentially (e.g. draft)
  ACTIONS = OpenProject::GithubIntegration::NotificationHandler::PullRequest::COMMENT_ACTIONS +
    %w[merged draft]

  def custom_actions
    @custom_actions ||= CustomAction.all.to_a
  end

  def selected?(github_action, custom_action)
    # TODO: robustness
    custom_action.id.to_s == Setting.plugin_openproject_github_integration["custom_field_mappings"][github_action]
  end

  def select_for(form, github_action)
    # TODO: I18n
    form.select_list(
      name: "custom_field_mappings[#{github_action}]",
      label: "For '#{github_action}'",
      include_blank: true,
      mb: 3
    ) do |opened_list|
      custom_actions.each do |action|
        opened_list.option(value: action.id, label: action.name, selected: selected?(github_action, action))
      end
    end
  end

  form do |settings_form|
    ACTIONS.each do |github_action|
      select_for(settings_form, github_action)
    end

    settings_form.submit(
      name: :submit,
      label: I18n.t(:button_save),
      scheme: :primary
    )
  end
end
