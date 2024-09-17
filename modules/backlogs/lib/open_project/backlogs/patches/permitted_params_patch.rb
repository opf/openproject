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

module OpenProject::Backlogs::Patches::PermittedParamsPatch
  def self.included(base)
    base.prepend InstanceMethods
  end

  module InstanceMethods
    def update_work_package(args = {})
      permitted_params = super

      backlogs_params = params.require(:work_package).permit(:story_points)
      permitted_params.merge!(backlogs_params)

      permitted_params
    end

    def my_account_settings
      backlogs_params = params.fetch(:backlogs, {}).permit(:task_color, :versions_default_fold_state)
      super.merge(backlogs: backlogs_params)
    end

    def backlogs_admin_settings
      params
        .require(:settings)
        .permit(:task_type, :points_burn_direction, :wiki_template, story_types: [])
    end
  end
end
PermittedParams.include OpenProject::Backlogs::Patches::PermittedParamsPatch
