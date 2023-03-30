#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

describe Calendar::IcalController do
  let(:project) { create(:project) }
  let(:user) do
    create(:user,
           member_in_project: project,
           member_with_permissions: sufficient_permissions)
  end
  let(:sufficient_permissions) { %i[view_work_packages share_calendars] }
  let(:valid_ical_token_value) { Token::ICal.create_and_return_value user }
  let(:query) do
    create(:query,
           project:,
           user:,
           public: false)
  end

  # the ical urls are intended to be used without a logged in user from a calendar client app
  # before { login_as(user) }

  describe '#show' do
    shared_examples_for 'ical#show' do |expected|
      subject { response }

      if expected == :success
        it { is_expected.to be_successful }
      end
      if expected == :failure
        it { is_expected.not_to be_successful }
      end
    end

    context 'with valid params' do
      before do
        get :show, params: {
          project_id: project.id,
          id: query.id,
          ical_token: valid_ical_token_value
        }
      end

      it_behaves_like 'ical#show', :success
    end

    context 'with invalid token' do
      before do
        get :show, params: {
          project_id: project.id,
          id: query.id,
          ical_token: SecureRandom.hex
        }
      end

      it_behaves_like 'ical#show', :failure
    end

    context 'with invalid query' do
      before do
        get :show, params: {
          project_id: project.id,
          id: SecureRandom.hex,
          ical_token: valid_ical_token_value
        }
      end

      it_behaves_like 'ical#show', :failure
    end

    context 'with invalid project' do
      before do
        get :show, params: {
          project_id: SecureRandom.hex,
          id: query.id,
          ical_token: valid_ical_token_value
        }
      end

      # TODO: the project id is actually irrelevant - the query id is enough
      # should the project id still be used in the ical url anyways?
      it_behaves_like 'ical#show', :success
    end
  end
end
