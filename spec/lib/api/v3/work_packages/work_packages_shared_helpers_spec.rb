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
  include ::API::V3::WorkPackages::WorkPackagesSharedHelpers

  # Literally mocking the environment for the test here
  # This is necessary since a module cannot be instantiated
  let(:env) { { 'api.request.body' => { subject: 'foo' } } }

  let(:work_package) { FactoryGirl.create(:work_package) }
  let(:current_user) { FactoryGirl.build(:admin) }

  before do
    allow(self).to receive(:status).with(an_instance_of(Fixnum))
  end

  describe '#create_work_package_form' do

    subject do
      create_work_package_form(work_package,
                               contract_class: ::API::V3::WorkPackages::CreateContract,
                               form_class: ::API::V3::WorkPackages::CreateFormRepresenter)
    end

    context 'valid parameters' do
      it 'should return a form' do
        expect(subject.is_a?(::API::V3::WorkPackages::CreateFormRepresenter)).to be_truthy
      end
    end

    context 'invalid parameters' do
      context 'validation errors' do
        let(:env) { { 'api.request.body' => { subject: '' } } }

        it 'does not raise for validation errors' do
          expect(subject.validation_errors.any?).to be_truthy
        end
      end

      context 'other errors' do
        let(:parent_wp) { FactoryGirl.create(:work_package, id: 5) }
        let(:env) { { 'api.request.body' => { percentageDone: 1, parentId: 5 } } }

        subject do
          lambda do
            create_work_package_form(work_package,
                                     contract_class: ::API::V3::WorkPackages::CreateContract,
                                     form_class: ::API::V3::WorkPackages::CreateFormRepresenter)
          end
        end

        before do
          allow(Setting).to receive(:work_package_done_ratio).and_return('status')
        end

        it 'should return all other errors' do
          expect(subject).to raise_error(API::Errors::UnwritableProperty)
        end
      end
    end
  end
end
