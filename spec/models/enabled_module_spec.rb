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

describe EnabledModule, type: :model do
  # Force reload, as association is not always(?) showing
  let(:project) { FactoryBot.create(:project, enabled_module_names: modules).reload }

  describe '#wiki' do
    let(:modules) { %w[wiki] }

    it 'creates a wiki' do
      expect(project.wiki).not_to be_nil
      expect(project.wiki.start_page).to eq('Wiki')
    end

    it 'should not create a separate wiki when one exists already' do
      expect(project.wiki).to_not be_nil

      expect {
        project.enabled_module_names = []
        project.reload
      }.to_not change { Wiki.count }

      expect {
        project.enabled_module_names = ['wiki']
      }.to_not change { Wiki.count }

      expect(project.wiki).to_not be_nil
    end

    context 'with disabled module' do
      let(:modules) { [] }

      it 'does not create a wiki' do
        expect(project.wiki).to be_nil
      end

      it 'creates a wiki when the module is enabled at a later time' do
        project.enabled_module_names = ['wiki']
        project.reload

        expect(project.wiki).to_not be_nil
        expect(project.wiki.start_page).to eq('Wiki')
      end
    end
  end

  describe '#repository' do
    let(:modules) { %w[repository] }

    before do
      allow(Setting).to receive(:repositories_automatic_managed_vendor).and_return(vendor)
    end

    shared_examples 'does not create a repository when one exists' do
      let!(:repository) { FactoryBot.create(:repository_git, project: project) }

      it 'should not create a separate repository when one exists already' do
        project.reload
        expect(project.repository).to_not be_nil

        expect {
          project.enabled_module_names = []
          project.reload
        }.to_not change { Repository.count }

        expect {
          project.enabled_module_names = ['repository']
        }.to_not change { Repository.count }

        expect(project.repository).to_not be_nil
      end
    end

    context 'with disabled setting' do
      let(:vendor) { nil }

      it 'does not create a repository' do
        expect(project.repository).to be_nil
      end

      it_behaves_like 'does not create a repository when one exists'
    end

    context 'with enabled setting' do
      let(:vendor) { 'git' }

      include_context 'with tmpdir'
      let(:config) {
        {
          git: { manages: File.join(tmpdir, 'git') }
        }
      }

      before do
        allow(Setting).to receive(:enabled_scm).and_return(['git'])
        allow(OpenProject::Configuration).to receive(:[]).and_call_original
        allow(OpenProject::Configuration).to receive(:[]).with('scm').and_return(config)
      end

      it 'creates a repository of the given vendor' do
        project.reload

        expect(project.repository).not_to be_nil
        expect(project.repository.vendor).to eq(:git)
        expect(project.repository.managed?).to be true
      end

      it 'does not remove the repository when setting is removed' do
        project.enabled_module_names = []
        project.reload

        expect(project.repository).not_to be_nil
      end

      it_behaves_like 'does not create a repository when one exists'
    end

    context 'with invalid setting' do
      let(:vendor) { 'some weird vendor' }

      it 'does not create a repository' do
        expect(project.repository).to be_nil
      end
    end
  end
end
