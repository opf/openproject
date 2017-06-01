#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module NoResultsHelper

  # Helper to render the /common/no_results partial custamizable content.
  # Example usage:
  # no_results_box action_url: new_project_version_path(@project),
  #                display_action: authorize_for('messages', 'new')
  #
  # All arguments are optional.
  #  - 'action_url' The url for the link in the content.
  #  - 'display_action' Whether or not the link should be displayed.
  #  - 'custom_title' custom text for the title.
  #  - 'custom_action_text' custom text for the title.
  #
  # Calling this on its on without any arguments creates the box in its simplest
  # form with only the title. Providing an action_url and display_action: true
  # Displays the box with the title and link to the passed in url.
  # The title and action_text are found using the locales key lookup unless
  # custom_title and custom_action_text are provided.
  def no_results_box(action_url:         nil,
                     display_action:     false,
                     custom_title:       nil,
                     custom_action_text: nil)

    title = custom_title || t('.no_results_title_text', cascade: true)
    action_text = custom_action_text || t('.no_results_content_text')

    render partial: '/common/no_results',
            locals: {
                      title_text:  title,
                      action_text: display_action ? action_text : '',
                      action_url:  action_url || ''
                    }
  end
end
