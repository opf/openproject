#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
#++

require 'spec_helper'
require 'contracts/work_packages/shared_base_contract'

describe WorkPackages::CreateContract do
  let(:work_package) { WorkPackage.new }
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:user) { FactoryBot.build_stubbed(:user) }

  subject(:contract) { described_class.new(work_package, user) }
  let(:validated_contract) do
    contract = subject
    contract.validate
    contract
  end

  it_behaves_like 'work package contract'

  def add_work_packages_allowed(in_project: true, in_global: true)
    allow(user)
      .to receive(:allowed_to?) do |permission, permission_project, global: false|
      (in_project && project == permission_project && permission == :add_work_packages) ||
        (in_global && global && permission == :add_work_packages)
    end
  end

  describe 'authorization' do
    context 'user allowed in project and project specified' do
      before do
        add_work_packages_allowed(in_project: true, in_global: true)

        work_package.project = project
      end

      it 'has no authorization error' do
        expect(validated_contract.errors[:base]).to be_empty
      end
    end

    context 'user not allowed in project and project specified' do
      before do
        add_work_packages_allowed(in_project: false, in_global: true)

        work_package.project = project
      end

      it 'is not authorized' do
        expect(validated_contract.errors.symbols_for(:base))
          .to match_array [:error_unauthorized]
      end
    end

    context 'user allowed in a project and no project specified' do
      before do
        add_work_packages_allowed(in_project: true, in_global: true)
      end

      it 'has no authorization error' do
        expect(validated_contract.errors[:base]).to be_empty
      end
    end

    context 'user not allowed in any project and no project specified' do
      before do
        add_work_packages_allowed(in_project: false, in_global: false)
      end

      it 'is not authorized' do
        expect(validated_contract.errors.symbols_for(:base))
          .to match_array [:error_unauthorized]
      end
    end

    context 'user not allowed in any project and project specified' do
      before do
        add_work_packages_allowed(in_project: false, in_global: false)

        work_package.project = project
      end

      it 'is not authorized' do
        expect(validated_contract.errors.symbols_for(:base))
          .to match_array [:error_unauthorized]
      end
    end
  end

  describe 'author_id' do
    before do
      add_work_packages_allowed(in_project: true, in_global: true)
      work_package.project = project
    end

    context 'if the user is set by the sytem and the user is the user the contract is evaluated for' do
      subject(:contract) { described_class.new(work_package, user, options: { changed_by_system: ['author_id'] }) }

      it 'is valid' do
        work_package.author = user

        expect(validated_contract.errors[:author_id]).to be_empty
      end
    end

    context 'if the user is different from the user the contract is evaluated for' do
      it 'is invalid' do
        work_package.author = FactoryBot.build_stubbed(:user)

        expect(validated_contract.errors.symbols_for(:author_id))
          .to match_array %i[invalid error_readonly]
      end
    end
  end
end
