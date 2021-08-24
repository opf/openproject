#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

# Return all users who want to be notified on every activity within a project.
# If there is only the global notification setting in place, that one is authoritative.
# If there is a project specific setting in place, it is the project specific setting instead.
module Users::Scopes
  module NotifiedOnAll
    extend ActiveSupport::Concern

    class_methods do
      def notified_on_all(project)
        global_settings = NotificationSetting
                          .where(all: true, project: nil)
        project_settings_not_all = NotificationSetting
                                   .where(project: project)
                                   .group(:user_id)
                                   .having('NOT bool_or("all")')
        project_settings = NotificationSetting
                           .where(all: true, project: project)

        where(id: global_settings.select(:user_id))
          .where.not(id: project_settings_not_all.select(:user_id))
          .or(User.where(id: project_settings.select(:user_id)))
      end
    end
  end
end
