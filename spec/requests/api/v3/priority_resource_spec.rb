#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'rack/test'
require 'pry'

describe 'API v3 Priority resource' do
  include Rack::Test::Methods

  let(:current_user) { FactoryGirl.create(:user) }
  let(:role) { FactoryGirl.create(:role, permissions: [:view_work_packages]) }
  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:priorities) { FactoryGirl.create_list(:priority, 2) }

  describe 'priorities' do
    subject(:response) { last_response }

    let(:get_path) { '/api/v3/priorities' }

    context 'logged in user' do
      before do
        allow(User).to receive(:current).and_return current_user
        member = FactoryGirl.build(:member, user: current_user, project: project)
        member.role_ids = [role.id]
        member.save!

        priorities

        get get_path
      end

      it_behaves_like 'API V3 collection response', 2, 2, 'Priority'
    end

    context 'not logged in user' do
      before do
        get get_path
      end

      it_behaves_like 'error response',
                      403,
                      'MissingPermission',
                      I18n.t('api_v3.errors.code_403')
    end
  end

  describe 'priorities/:id' do
    subject(:response) { last_response }

    let(:get_path) { "/api/v3/priorities/#{priorities.first.id}" }

    context 'logged in user' do
      before do
        allow(User).to receive(:current).and_return current_user
        member = FactoryGirl.build(:member, user: current_user, project: project)
        member.role_ids = [role.id]
        member.save!

        priorities

        get get_path
      end

      context 'valid priority id' do
        it 'should return HTTP 200' do
          expect(response.status).to eql(200)
        end
      end

      context 'invalid priority id' do
        let(:get_path) { '/api/v3/priorities/bogus' }

        it_behaves_like 'not found' do
          let(:id) { 'bogus' }
          let(:type) { 'IssuePriority' }
        end
      end
    end

    context 'not logged in user' do
      before do
        get get_path
      end

      it_behaves_like 'error response',
                      403,
                      'MissingPermission',
                      I18n.t('api_v3.errors.code_403')
    end
  end
end
