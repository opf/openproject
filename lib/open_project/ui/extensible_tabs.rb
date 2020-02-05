#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module OpenProject
  module Ui
    class ExtensibleTabs
      class << self
        def tabs
          @@tabs ||= {
            user: core_user_tabs
          }
        end

        ##
        # Get all enabled tabs for the given key
        def enabled_tabs(key, context = {})
          tabs[key].select { |entry| entry[:only_if].nil? || entry[:only_if].call(context) }
        end

        # Add a new tab for the given key
        def add(key, **entry)
          tabs[key] = [] if tabs[key].nil?

          raise ArgumentError.new "Invalid entry for tab #{key}" unless entry[:name] && entry[:partial]
          tabs[key] << entry
        end

        private

        def core_user_tabs
          [
            {
              name: 'general',
              partial: 'users/general',
              path: ->(params) { tab_edit_user_path(params[:user], tab: :general) },
              label: :label_general
            },
            {
              name: 'memberships',
              partial: 'users/memberships',
              path: ->(params) { tab_edit_user_path(params[:user], tab: :memberships) },
              label: :label_project_plural
            },
            {
              name: 'groups',
              partial: 'users/groups',
              path: ->(params) { tab_edit_user_path(params[:user], tab: :groups) },
              label: :label_group_plural, if: ->(*) { Group.all.any? }
            }
          ]
        end
      end
    end
  end
end
