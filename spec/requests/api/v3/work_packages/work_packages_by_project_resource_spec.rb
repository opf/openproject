#-- encoding: UTF-8
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

require 'spec_helper'
require 'rack/test'

describe API::V3::WorkPackages::WorkPackagesByProjectAPI, type: :request do
  include Rack::Test::Methods
  include API::V3::Utilities::PathHelper

  let(:project) { FactoryGirl.create(:project_with_types, is_public: false) }

  describe '#post' do
    let(:status) { FactoryGirl.build(:status, is_default: true) }
    let(:priority) { FactoryGirl.build(:priority, is_default: true) }
    let(:parameters) { { subject: 'new work packages' } }
    let(:permissions) { [:add_work_packages, :view_project] }
    let(:role) { FactoryGirl.create(:role, permissions: permissions) }
    let(:current_user) do
      user = FactoryGirl.create(:user, member_in_project: project, member_through_role: role)
      FactoryGirl.create(:user_preference, user: user, others: { no_self_notified: false })

      user
    end
    let(:path) { api_v3_paths.work_packages_by_project project.id }

    before do
      status.save!
      priority.save!

      allow(User).to receive(:current).and_return current_user
      ActionMailer::Base.deliveries.clear
      post path, parameters.to_json, 'CONTENT_TYPE' => 'application/json'
    end

    context 'notifications' do
      let(:permissions) { [:add_work_packages, :view_project, :view_work_packages] }

      it 'sends a mail by default' do
        expect(ActionMailer::Base.deliveries.count).to eq(1)
      end

      context 'without notifications' do
        let(:path) { "#{api_v3_paths.work_packages_by_project(project.id)}?notify=false" }

        it 'should not send a mail' do
          expect(ActionMailer::Base.deliveries.count).to eq(0)
        end
      end

      context 'with notifications' do
        let(:path) { "#{api_v3_paths.work_packages_by_project(project.id)}?notify=true" }

        it 'should send a mail' do
          expect(ActionMailer::Base.deliveries.count).to eq(1)
        end
      end
    end

    it 'should return Created(201)' do
      expect(last_response.status).to eq(201)
    end

    it 'should create a work package' do
      expect(WorkPackage.all.count).to eq(1)
    end

    it 'should use the given parameters' do
      expect(WorkPackage.first.subject).to eq(parameters[:subject])
    end

    context 'no permissions' do
      let(:current_user) { FactoryGirl.build(:user) }

      it 'should hide the endpoint' do
        expect(last_response.status).to eq(404)
      end
    end

    context 'view_project permission' do
      # Note that this just removes the add_work_packages permission
      # view_project is actually provided by being a member of the project
      let(:permissions) { [:view_project] }

      it 'should point out the missing permission' do
        expect(last_response.status).to eq(403)
      end
    end

    context 'empty parameters' do
      let(:parameters) { {} }

      it_behaves_like 'constraint violation' do
        let(:message) { "Subject can't be blank" }
      end

      it 'should not create a work package' do
        expect(WorkPackage.all.count).to eq(0)
      end
    end

    context 'bogus parameters' do
      let(:parameters) { { bogus: nil } }

      it_behaves_like 'constraint violation' do
        let(:message) { "Subject can't be blank" }
      end

      it 'should not create a work package' do
        expect(WorkPackage.all.count).to eq(0)
      end
    end

    context 'invalid value' do
      let(:parameters) { { subject: nil } }

      it_behaves_like 'constraint violation' do
        let(:message) { "Subject can't be blank" }
      end

      it 'should not create a work package' do
        expect(WorkPackage.all.count).to eq(0)
      end
    end
  end
end
