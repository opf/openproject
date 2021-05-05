#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
#++

require 'spec_helper'

describe Queries::WorkPackages::Filter::PrincipalLoader, type: :model do
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:group) { FactoryBot.build_stubbed(:group) }
  let(:placeholder_user) { FactoryBot.build_stubbed(:placeholder_user) }
  let(:project) { FactoryBot.build_stubbed(:project) }
  let(:instance) { described_class.new(project) }

  context 'with a project' do
    before do
      allow(project)
        .to receive(:principals)
        .and_return([user, group, placeholder_user])
    end

    describe '#user_values' do
      it 'returns a user array' do
        expect(instance.user_values).to match_array([[user.name, user.id.to_s]])
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
        expect(instance.group_values).to match_array([[group.name, group.id.to_s]])
      end

      it 'is empty if no group exists' do
        allow(project)
          .to receive(:principals)
          .and_return([])

        expect(instance.group_values).to be_empty
      end
    end

    describe '#principal_values' do
      it 'returns an array of principals as [name, id]' do
        expect(instance.principal_values)
          .to match_array([[group.name, group.id.to_s],
                           [user.name, user.id.to_s],
                           [placeholder_user.name, placeholder_user.id.to_s]])
      end

      it 'is empty if no principal exists' do
        allow(project)
          .to receive(:principals)
          .and_return([])

        expect(instance.principal_values).to be_empty
      end
    end
  end

  context 'without a project' do
    let(:project) { nil }
    let(:visible_projects) { [FactoryBot.build_stubbed(:project)] }
    let(:matching_principals) { [user, group, placeholder_user] }

    before do
      allow(Principal)
        .to receive_message_chain(:not_locked, :in_visible_project)
        .and_return(matching_principals)
    end

    describe '#user_values' do
      it 'returns a user array' do
        expect(instance.user_values).to match_array([[user.name, user.id.to_s]])
      end

      context 'no user exists' do
        let(:matching_principals) { [group] }

        it 'is empty' do
          expect(instance.user_values).to be_empty
        end
      end
    end

    describe '#group_values' do
      it 'returns a group array' do
        expect(instance.group_values).to match_array([[group.name, group.id.to_s]])
      end

      context 'no group exists' do
        let(:matching_principals) { [user] }

        it 'is empty' do
          expect(instance.group_values).to be_empty
        end
      end
    end

    describe '#principal_values' do
      it 'returns an array of principals as [name, id]' do
        expect(instance.principal_values)
          .to match_array([[group.name, group.id.to_s],
                           [user.name, user.id.to_s],
                           [placeholder_user.name, placeholder_user.id.to_s]])
      end

      context 'no principals' do
        let(:matching_principals) { [] }

        it 'is empty' do
          expect(instance.principal_values).to be_empty
        end
      end
    end
  end
end
