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

describe Queries::WorkPackages::Filter::PrincipalLoader, type: :model do
  let(:user_1) { FactoryBot.build_stubbed(:user) }
  let(:group_1) { FactoryBot.build_stubbed(:group) }
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:instance) { described_class.new(project) }

  context 'with a project' do
    before do
      allow(project)
        .to receive(:principals)
        .and_return([user_1, group_1])
    end

    describe '#user_values' do
      it 'returns a user array' do
        expect(instance.user_values).to match_array([[user_1.name, user_1.id.to_s]])
      end

      it 'is empty if no user exists' do
        allow(project)
          .to receive(:principals)
          .and_return([])

        expect(instance.user_values).to be_empty
      end
    end

    describe '#group_values' do
      it 'returns a group array' do
        expect(instance.group_values).to match_array([[group_1.name, group_1.id.to_s]])
      end

      it 'is empty if no group exists' do
        allow(project)
          .to receive(:principals)
          .and_return([])

        expect(instance.group_values).to be_empty
      end
    end
  end

  context 'without a project' do
    let(:project) { nil }
    let(:visible_projects) { [FactoryBot.build_stubbed(:project)] }
    let(:matching_principals) { [user_1, group_1] }

    before do
      allow(Principal)
        .to receive_message_chain(:active_or_registered, :in_visible_project)
        .and_return(matching_principals)
    end

    describe '#user_values' do
      it 'returns a user array' do
        expect(instance.user_values).to match_array([[user_1.name, user_1.id.to_s]])
      end

      context 'no user exists' do
        let(:matching_principals) { [group_1] }

        it 'is empty' do
          expect(instance.user_values).to be_empty
        end
      end
    end

    describe '#group_values' do
      it 'returns a group array' do
        expect(instance.group_values).to match_array([[group_1.name, group_1.id.to_s]])
      end

      context 'no group exists' do
        let(:matching_principals) { [user_1] }

        it 'is empty' do
          expect(instance.group_values).to be_empty
        end
      end
    end
  end
end
