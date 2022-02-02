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
require_relative './show_resource_examples'

describe ::API::V3::Notifications::NotificationsAPI,
         'show',
         content_type: :json,
         type: :request do
  include API::V3::Utilities::PathHelper

  shared_let(:recipient) do
    create :user
  end
  shared_let(:role) { create(:role, permissions: %i(view_work_packages)) }
  shared_let(:project) do
    create :project,
                      members: { recipient => role }
  end
  shared_let(:resource) { create :work_package, project: project }
  shared_let(:notification) do
    create :notification,
                      recipient: recipient,
                      project: project,
                      resource: resource,
                      journal: resource.journals.last
  end

  let(:send_request) do
    get api_v3_paths.notification(notification.id)
  end

  before do
    login_as current_user
    send_request
  end

  describe 'recipient user' do
    let(:current_user) { recipient }

    it_behaves_like 'represents the notification'
  end

  describe 'admin user' do
    let(:current_user) { build(:admin) }

    it 'returns a 404 response' do
      expect(last_response.status).to eq(404)
    end
  end

  describe 'unauthorized user' do
    let(:current_user) { build(:user) }

    it 'returns a 404 response' do
      expect(last_response.status).to eq(404)
    end
  end
end
