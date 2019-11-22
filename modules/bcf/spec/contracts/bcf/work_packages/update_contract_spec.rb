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

describe Bcf::WorkPackages::UpdateContract do
  let(:project) do
    FactoryBot.build_stubbed(:project)
  end
  let(:work_package) do
    FactoryBot.build_stubbed(:work_package,
                             project: project,
                             type: type)
  end
  let(:current_user) { FactoryBot.build_stubbed(:user) }
  let(:type) { FactoryBot.build_stubbed(:type) }
  let(:permissions) { %i[view_work_packages edit_work_packages] }

  before do
    allow(current_user)
      .to receive(:allowed_to?) do |permission, context|
      permissions.include?(permission) && context == project
    end
  end

  subject(:contract) { described_class.new(work_package, current_user) }

  describe 'status' do
    let(:roles) { [FactoryBot.build_stubbed(:role)] }
    let(:valid_transition_result) { true }
    let(:new_status) { FactoryBot.build_stubbed(:status) }
    let(:from_id) { work_package.status_id }
    let(:to_id) { new_status.id }
    let(:status_change) { work_package.status = new_status }

    before do
      allow(current_user)
        .to receive(:roles)
        .with(work_package.project)
        .and_return(roles)

      allow(type)
        .to receive(:valid_transition?)
        .with(from_id,
              to_id,
              roles)
        .and_return(valid_transition_result)

      status_change

      contract.validate
    end

    context 'valid transition' do
      it 'is valid' do
        expect(subject.errors.symbols_for(:status_id))
          .to be_empty
      end
    end

    context 'invalid transition' do
      let(:valid_transition_result) { false }

      it 'is invalid' do
        expect(subject.errors.symbols_for(:status_id))
          .to match_array [:status_transition_invalid]
      end
    end

    context 'invalid transition to default status' do
      let(:new_status) { FactoryBot.build_stubbed(:status, is_default: true) }
      let(:valid_transition_result) { false }

      it 'is valid' do
        expect(subject.errors.symbols_for(:status_id))
          .to be_empty
      end
    end
  end
end
