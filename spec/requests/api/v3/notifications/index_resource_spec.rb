#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

require 'spec_helper'
require 'rack/test'

describe ::API::V3::Notifications::NotificationsAPI,
         'index',
         type: :request,
         content_type: :json do

  include API::V3::Utilities::PathHelper

  shared_let(:work_package) { FactoryBot.create :work_package }
  shared_let(:recipient) do
    FactoryBot.create :user,
                      member_in_project: work_package.project,
                      member_with_permissions: %i[view_work_packages]
  end
  shared_let(:notification1) { FactoryBot.create :notification, recipient: recipient, resource: work_package }
  shared_let(:notification2) { FactoryBot.create :notification, recipient: recipient, resource: work_package }

  let(:notifications) { [notification1, notification2] }

  let(:filters) { nil }

  let(:send_request) do
    get api_v3_paths.path_for :notifications, filters: filters
  end

  let(:parsed_response) { JSON.parse(last_response.body) }

  before do
    notifications

    login_as current_user

    send_request
  end

  describe 'as the user with notifications' do
    let(:current_user) { recipient }

    it_behaves_like 'API V3 collection response', 2, 2, 'Notification'

    context 'with a digest notification' do
      let(:digest_notification) { FactoryBot.create :notification, recipient: recipient, reason_ian: nil }
      let(:notifications) { [notification1, notification2, digest_notification] }

      it_behaves_like 'API V3 collection response', 2, 2, 'Notification' do
        let(:elements) { [notification2, notification1] }
      end
    end

    context 'with a readIAN filter' do
      let(:nil_notification) { FactoryBot.create :notification, recipient: recipient, read_ian: nil }

      let(:notifications) { [notification1, notification2, nil_notification] }

      let(:filters) do
        [
          {
            'readIAN' => {
              'operator' => '=',
              'values' => ['f']

            }
          }
        ]
      end

      context 'with the filter being set to false' do
        it_behaves_like 'API V3 collection response', 2, 2, 'Notification' do
          let(:elements) { [notification2, notification1] }
        end
      end
    end

    context 'with a resource filter' do
      let(:notification3) { FactoryBot.create :notification, recipient: recipient }
      let(:notifications) { [notification1, notification2, notification3] }

      let(:filters) do
        [
          {
            'resourceId' => {
              'operator' => '=',
              'values' => [work_package.id.to_s]
            }
          },
          {
            'resourceType' => {
              'operator' => '=',
              'values' => [WorkPackage.name.to_s]
            }
          }
        ]
      end

      context 'with the filter being set to false' do
        it_behaves_like 'API V3 collection response', 2, 2, 'Notification' do
          let(:elements) { [notification2, notification1] }
        end
      end
    end
  end

  describe 'admin user' do
    let(:current_user) { FactoryBot.build(:admin) }

    it_behaves_like 'API V3 collection response', 0, 0, 'Notification'
  end

  describe 'as any user' do
    let(:current_user) { FactoryBot.build(:user) }

    it_behaves_like 'API V3 collection response', 0, 0, 'Notification'
  end

  describe 'as an anyonymous user' do
    let(:current_user) { User.anonymous }

    it 'returns a 403 response' do
      expect(last_response.status).to eq(403)
    end
  end
end
