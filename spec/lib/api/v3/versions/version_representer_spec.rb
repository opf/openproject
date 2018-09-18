#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe ::API::V3::Versions::VersionRepresenter do
  let(:version) { FactoryBot.build_stubbed(:version) }
  let(:user) { FactoryBot.build_stubbed(:user) }
  let(:representer) { described_class.new(version, current_user: user) }

  include API::V3::Utilities::PathHelper

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { is_expected.to include_json('Version'.to_json).at_path('_type') }

    describe 'links' do
      it { is_expected.to have_json_type(Object).at_path('_links') }

      describe 'to self' do
        it_behaves_like 'has a titled link' do
          let(:link) { 'self' }
          let(:href) { api_v3_paths.version(version.id) }
          let(:title) { version.name }
        end
      end

      describe 'to the defining project' do
        context 'if the user has the permission to see the project' do
          before do
            allow(version.project).to receive(:visible?).with(user).and_return(true)
          end

          it_behaves_like 'has a titled link' do
            let(:link) { 'definingProject' }
            let(:href) { api_v3_paths.project(version.project.id) }
            let(:title) { version.project.name }
          end
        end

        context 'if the user lacks the permission to see the project' do
          before do
            allow(version.project).to receive(:visible?).with(user).and_return(false)
          end

          it_behaves_like 'has no link' do
            let(:link) { 'definingProject' }
          end
        end
      end

      describe 'to available projects' do
        it_behaves_like 'has an untitled link' do
          let(:link) { 'availableInProjects' }
          let(:href) { api_v3_paths.projects_by_version(version.id) }
        end
      end
    end

    describe 'version' do
      it { is_expected.to be_json_eql(version.id.to_json).at_path('id') }
      it { is_expected.to be_json_eql(version.name.to_json).at_path('name') }

      it_behaves_like 'API V3 formattable', 'description' do
        let(:format) { 'plain' }
        let(:raw) { version.description }
      end

      it_behaves_like 'has ISO 8601 date only' do
        let(:date) { version.start_date }
        let(:json_path) { 'startDate' }
      end

      it_behaves_like 'has ISO 8601 date only' do
        let(:date) { version.due_date }
        let(:json_path) { 'endDate' }
      end

      it { is_expected.to be_json_eql(version.status.to_json).at_path('status') }

      it_behaves_like 'has UTC ISO 8601 date and time' do
        let(:date) { version.created_on }
        let(:json_path) { 'createdAt' }
      end

      it_behaves_like 'has UTC ISO 8601 date and time' do
        let(:date) { version.updated_on }
        let(:json_path) { 'updatedAt' }
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

      describe '#json_cache_key' do
        let!(:former_cache_key) { representer.json_cache_key }

        it 'includes the name of the representer class' do
          expect(representer.json_cache_key)
            .to include('API', 'V3', 'Versions', 'VersionRepresenter')
        end

        it 'changes when the locale changes' do
          I18n.with_locale(:fr) do
            expect(representer.json_cache_key)
              .not_to eql former_cache_key
          end
        end

        it 'changes when the version is updated' do
          version.updated_on = Time.now + 20.seconds

          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end

        it 'changes when the version\'s project is updated' do
          version.project.updated_on = Time.now + 20.seconds

          expect(representer.json_cache_key)
            .not_to eql former_cache_key
        end
      end
    end
  end
end
