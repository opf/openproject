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

class OpenProject::Backlogs::Hooks::UserSettingsHook < OpenProject::Hook::ViewListener
  # Updates the backlogs settings before saving the user
  #
  # Context:
  # * params => Request parameters
  # * permitted_params => whitelisted params
  # * user => user being altered
  def service_update_user_before_save(context = {})
    params = context[:params]
    user = context[:user]

    backlogs_params = params.delete(:backlogs)
    return unless backlogs_params

    versions_default_fold_state = backlogs_params[:versions_default_fold_state] || "open"
    user.backlogs_preference(:versions_default_fold_state, versions_default_fold_state)

    color = backlogs_params[:task_color] || ""
    if color == "" || color.match(/^#[A-Fa-f0-9]{6}$/)
      user.backlogs_preference(:task_color, color)
    end
  end
end
