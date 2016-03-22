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

describe ::API::V3::WorkPackages::WorkPackagesSharedHelpers do
  let(:project) { FactoryGirl.create(:project, is_public: false) }
  let(:work_package) { FactoryGirl.create(:work_package, project: project) }
  let(:user) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
  let(:role) { FactoryGirl.create(:role, permissions: permissions) }
  let(:permissions) { [:view_work_packages, :add_work_packages] }
  let(:env) { { 'api.request.body' => { 'subject' => 'foo' } } }

  let(:helper_class) {
    Class.new do
      include ::API::V3::WorkPackages::WorkPackagesSharedHelpers

      def initialize(user, env)
        @user = user
        @env = env
      end

      def env
        @env
      end

      def request_body
        @env['api.request.body']
      end

      def current_user
        @user
      end

      def status(_code)
      end
    end
  }
  let(:helper) { helper_class.new(user, env) }

  describe '#create_work_package_form' do
    subject do
      helper.create_work_package_form(work_package,
                                      contract_class: ::WorkPackages::CreateContract,
                                      form_class: ::API::V3::WorkPackages::CreateFormRepresenter)
    end

    context 'valid parameters' do
      it 'should return a form' do
        expect(subject).to be_a(::API::V3::WorkPackages::CreateFormRepresenter)
      end

      it 'should pass the request body into the form' do
        expect(subject.to_json).to be_json_eql('foo'.to_json).at_path('_embedded/payload/subject')
      end
    end

    context 'invalid parameters' do
      context 'attribute specific errors' do
        let(:env) { { 'api.request.body' => { 'subject' => '' } } }

        it 'does not raise' do
          expect(subject.validation_errors).to_not be_empty
        end
      end

      context 'general errors' do
        let(:permissions) { [:view_work_packages] }

        it 'should raise' do
          expect { subject }.to raise_error(API::Errors::Unauthorized)
        end
      end
    end
  end
end
