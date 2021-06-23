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
# See docs/COPYRIGHT.rdoc for more details.

require 'spec_helper'
require_relative './show_resource_examples'

describe ::API::V3::Notifications::NotificationsAPI,
         'show',
         type: :request do
  include API::V3::Utilities::PathHelper

  shared_let(:recipient) { FactoryBot.create :user }
  shared_let(:project) { FactoryBot.create :project }
  shared_let(:resource) { FactoryBot.create :work_package, project: project }
  shared_let(:notification) do
    FactoryBot.create :notification,
                      recipient: recipient,
                      project: project,
                      resource: resource,
                      journal: resource.journals.last
  end

  let(:send_request) do
    header "Content-Type", "application/json"
    get api_v3_paths.notification(notification.id)
  end

  let(:parsed_response) { JSON.parse(last_response.body) }

  before do
    login_as current_user
    send_request
  end

  describe 'recipient user' do
    let(:current_user) { recipient }

    it_behaves_like 'represents the notification'
  end

  describe 'admin user' do
    let(:current_user) { FactoryBot.build(:admin) }

    it 'returns a 404 response' do
      expect(last_response.status).to eq(404)
    end
  end

  describe 'unauthorized user' do
    let(:current_user) { FactoryBot.build(:user) }

    it 'returns a 404 response' do
      expect(last_response.status).to eq(404)
    end
  end
end
