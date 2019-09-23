#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

class OpenProject::Costs::Hooks::UserSettingsHook < Redmine::Hook::ViewListener

  # Updates the backlogs settings before saving the user
  #
  # Context:
  # * params => Request parameters
  # * permitted_params => whitelisted params
  # * user => user being altered
  def service_update_user_before_save(context = {})
    params = context[:params]
    user = context[:user]
    return unless params[:backlogs]

    versions_default_fold_state = params.dig(:backlogs, :versions_default_fold_state) || 'open'
    user.backlogs_preference(:versions_default_fold_state, versions_default_fold_state)

    color = params.dig(:backlogs, :task_color) || ''
    if color == '' || color.match(/^#[A-Fa-f0-9]{6}$/)
      user.backlogs_preference(:task_color, color)
    end
  end
end
