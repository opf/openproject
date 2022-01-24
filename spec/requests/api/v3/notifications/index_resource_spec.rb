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

  shared_let(:work_package) { create :work_package }
  shared_let(:recipient) do
    create :user,
                      member_in_project: work_package.project,
                      member_with_permissions: %i[view_work_packages]
  end
  shared_let(:notification1) do
    create :notification,
                      recipient: recipient,
                      resource: work_package,
                      project: work_package.project,
                      journal: work_package.journals.first
  end
  shared_let(:notification2) do
    create :notification,
                      recipient: recipient,
                      resource: work_package,
                      project: work_package.project,
                      journal: work_package.journals.first
  end

  let(:notifications) { [notification1, notification2] }

  let(:filters) { nil }

  let(:send_request) do
    get api_v3_paths.path_for :notifications, filters: filters
  end

  let(:parsed_response) { JSON.parse(last_response.body) }
  let(:additional_setup) do
    # To be overwritten by individual specs
  end

  before do
    notifications

    login_as current_user
    additional_setup

    send_request
  end

  describe 'as the user with notifications' do
    let(:current_user) { recipient }

    it_behaves_like 'API V3 collection response', 2, 2, 'Notification'

    context 'with a readIAN filter' do
      let(:nil_notification) { create :notification, recipient: recipient, read_ian: nil }

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
      let(:notification3) { create :notification, recipient: recipient }
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

    context 'with a project filter' do
      let(:other_work_package) { create(:work_package) }
      let(:notification3) do
        create :notification,
                          recipient: recipient,
                          resource: other_work_package,
                          project: other_work_package.project
      end
      let(:notifications) { [notification1, notification2, notification3] }

      let(:filters) do
        [
          {
            'project' => {
              'operator' => '=',
              'values' => [work_package.project_id.to_s]
            }
          }
        ]
      end

      it_behaves_like 'API V3 collection response', 2, 2, 'Notification' do
        let(:elements) { [notification2, notification1] }
      end
    end

    context 'with a reason filter' do
      let(:notification3) do
        create :notification,
                          reason: :assigned,
                          recipient: recipient,
                          resource: work_package,
                          project: work_package.project,
                          journal: work_package.journals.first
      end
      let(:notification4) do
        create :notification,
                          reason: :responsible,
                          recipient: recipient,
                          resource: work_package,
                          project: work_package.project,
                          journal: work_package.journals.first
      end
      let(:notifications) { [notification1, notification2, notification3, notification4] }

      let(:filters) do
        [
          {
            'reason' => {
              'operator' => '=',
              'values' => [notification1.reason.to_s, notification4.reason.to_s]
            }
          }
        ]
      end

      it_behaves_like 'API V3 collection response', 3, 3, 'Notification' do
        let(:elements) { [notification4, notification2, notification1] }
      end

      context 'with an invalid reason' do
        let(:filters) do
          [
            {
              'reason' => {
                'operator' => '=',
                'values' => ['bogus']
              }
            }
          ]
        end

        it 'returns an error' do
          expect(last_response.status)
            .to be 400

          expect(last_response.body)
            .to be_json_eql("Filters Reason filter has invalid values.".to_json)
                  .at_path('message/0')
        end
      end
    end

    context 'with a non ian notification' do
      let(:wiki_page) { create(:wiki_page_with_content) }

      let(:non_ian_notification) do
        create :notification,
                          read_ian: nil,
                          recipient: recipient,
                          resource: wiki_page,
                          project: wiki_page.wiki.project,
                          journal: wiki_page.content.journals.first
      end

      let(:notifications) { [notification2, notification1, non_ian_notification] }

      it_behaves_like 'API V3 collection response', 2, 2, 'Notification' do
        let(:elements) { [notification2, notification1] }
      end
    end

    context 'with a reason groupBy' do
      let(:responsible_notification) do
        create :notification,
                          recipient: recipient,
                          reason: :responsible,
                          resource: work_package,
                          project: work_package.project,
                          journal: work_package.journals.first
      end

      let(:notifications) { [notification1, notification2, responsible_notification] }

      let(:send_request) do
        get api_v3_paths.path_for :notifications, group_by: :reason
      end

      let(:groups) { parsed_response['groups'] }

      it_behaves_like 'API V3 collection response', 3, 3, 'Notification'

      it 'contains the reason groups', :aggregate_failures do
        expect(groups).to be_a Array
        expect(groups.count).to eq 2

        keyed = groups.index_by { |el| el['value'] }
        expect(keyed.keys).to contain_exactly 'mentioned', 'responsible'
        expect(keyed['mentioned']['count']).to eq 2
        expect(keyed['responsible']['count']).to eq 1
      end
    end

    context 'with a project groupBy' do
      let(:other_project) do
        create(:project,
                          members: { recipient => recipient.members.first.roles })
      end
      let(:work_package2) { create :work_package, project: other_project }
      let(:other_project_notification) do
        create :notification,
                          resource: work_package2,
                          project: other_project,
                          recipient: recipient,
                          reason: :responsible,
                          journal: work_package2.journals.first
      end

      let(:notifications) { [notification1, notification2, other_project_notification] }

      let(:send_request) do
        get api_v3_paths.path_for :notifications, group_by: :project
      end

      let(:groups) { parsed_response['groups'] }

      it_behaves_like 'API V3 collection response', 3, 3, 'Notification'

      it 'contains the project groups', :aggregate_failures do
        expect(groups).to be_a Array
        expect(groups.count).to eq 2

        keyed = groups.index_by { |el| el['value'] }
        expect(keyed.keys).to contain_exactly other_project.name, work_package.project.name
        expect(keyed[work_package.project.name]['count']).to eq 2
        expect(keyed[work_package2.project.name]['count']).to eq 1

        expect(keyed.dig(work_package.project.name, '_links', 'valueLink')[0]['href'])
          .to eq "/api/v3/projects/#{work_package.project.id}"
      end
    end

    context 'when having lost the permission to see the work package' do
      let(:additional_setup) do
        Member.where(principal: recipient).destroy_all
      end

      it_behaves_like 'API V3 collection response', 0, 0, 'Notification'
    end
  end

  describe 'admin user' do
    let(:current_user) { build(:admin) }

    it_behaves_like 'API V3 collection response', 0, 0, 'Notification'
  end

  describe 'as any user' do
    let(:current_user) { build(:user) }

    it_behaves_like 'API V3 collection response', 0, 0, 'Notification'
  end

  describe 'as an anyonymous user' do
    let(:current_user) { User.anonymous }

    it 'returns a 403 response' do
      expect(last_response.status).to eq(403)
    end
  end
end
