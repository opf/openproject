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

describe ::API::V3::Groups::GroupRepresenter do
  let(:group) { FactoryBot.build_stubbed(:group) }
  let(:current_user) { FactoryBot.build_stubbed(:user) }
  let(:representer) { described_class.new(group, current_user: current_user) }

  context 'generation' do
    subject(:generated) { representer.to_json }

    it do is_expected.to include_json('Group'.to_json).at_path('_type') end

    context 'as regular user' do
      it 'has an id property' do
        is_expected
          .to be_json_eql(group.id.to_json)
          .at_path('id')
      end

      it 'has a name property' do
        is_expected
          .to be_json_eql(group.name.to_json)
          .at_path('name')
      end

      it 'hides the updatedAt property' do
        is_expected.not_to have_json_path('updatedAt')
      end

      it 'hides the createdAt property' do
        is_expected.not_to have_json_path('createdAt')
      end
    end

    context 'as admin' do
      let(:current_user) { FactoryBot.build_stubbed(:admin) }

      it 'has an id property' do
        is_expected
          .to be_json_eql(group.id.to_json)
          .at_path('id')
      end

      it 'has a name property' do
        is_expected
          .to be_json_eql(group.name.to_json)
          .at_path('name')
      end

      it_behaves_like 'has UTC ISO 8601 date and time' do
        let(:date) { group.created_on }
        let(:json_path) { 'createdAt' }
      end

      it_behaves_like 'has UTC ISO 8601 date and time' do
        let(:date) { group.updated_on }
        let(:json_path) { 'updatedAt' }
      end
    end

    describe '_links' do
      it 'should link to self' do
        expect(subject).to have_json_path('_links/self/href')
      end
    end

    describe 'caching' do
      it 'is based on the representer\'s cache_key' do
        expect(OpenProject::Cache)
          .to receive(:fetch)
          .with(representer.json_cache_key)
          .and_call_original

        representer.to_json
      end

      describe 'caching' do
        it 'is based on the representer\'s cache_key' do
          expect(OpenProject::Cache)
            .to receive(:fetch)
            .with(representer.json_cache_key)
            .and_call_original

          representer.to_json
        end

        describe '#json_cache_key' do
          let!(:former_cache_key) { representer.json_cache_key }

          it 'includes the name of the representer class' do
            expect(representer.json_cache_key)
              .to include('API', 'V3', 'Groups', 'GroupRepresenter')
          end

          it 'changes when the locale changes' do
            I18n.with_locale(:fr) do
              expect(representer.json_cache_key)
                .not_to eql former_cache_key
            end
          end

          it 'changes when the group is updated' do
            group.updated_on = Time.now + 20.seconds

            expect(representer.json_cache_key)
              .not_to eql former_cache_key
          end
        end
      end
    end
  end
end
