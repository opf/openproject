#  OpenProject is an open source project management software.
#  Copyright (C) 2010-2022 the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

require 'spec_helper'

RSpec.describe Redmine::MenuManager do
  describe '.items' do
    context 'for the top_menu' do
      it 'includes the expected items' do
        expect(described_class.items(:top_menu).map(&:name))
          .to include(:work_packages, :news, :help)
      end
    end

    context 'for the account_menu' do
      it 'includes the expected items' do
        expect(described_class.items(:account_menu).map(&:name))
          .to include(:administration, :my_account, :my_page, :logout)
      end
    end

    context 'for the project_menu' do
      it 'includes the expected items' do
        expect(described_class.items(:project_menu).map(&:name))
          .to include(:overview, :activity, :roadmap, :work_packages, :news, :forums, :repository, :settings)
      end
    end

    context 'for the global_work_packages_menu' do
      it 'includes the expected items' do
        expect(described_class.items(:global_work_packages_menu).map(&:name))
          .to include(:work_packages_query_select)
      end
    end

    context 'for the global_activities_menu' do
      it 'includes the expected items' do
        expect(described_class.items(:global_activities_menu).map(&:name))
          .to include(:activity_filters)
      end
    end

    context 'for the notifications_menu' do
      it 'includes the expected items' do
        expect(described_class.items(:notifications_menu).map(&:name))
          .to include(:notification_grouping_select)
      end
    end

    context 'for the my_menu' do
      it 'includes the expected items' do
        expect(described_class.items(:my_menu).map(&:name))
          .to include(:account, :settings, :password, :access_token, :notifications, :reminders, :delete_account)
      end
    end

    context 'for the admin_menu' do
      it 'includes the expected items' do
        expect(described_class.items(:admin_menu).map(&:name))
          .to include(:admin_overview,
                      :users,
                      :placeholder_users,
                      :groups,
                      :custom_fields,
                      :authentication,
                      :announcements)
      end

      it 'has children defined for the authentication item' do
        expect(described_class.items(:admin_menu).find { |item| item.name == :authentication }.map(&:name))
          .to include(:authentication_settings,
                      :ldap_authentication,
                      :oauth_applications)
      end
    end
  end
end
