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

describe Scm::DeleteManagedRepositoryService do
  let(:user) { FactoryGirl.build(:user) }
  let(:project) { FactoryGirl.build(:project) }

  let(:repository) { FactoryGirl.build(:repository_subversion) }
  subject(:service) { Scm::DeleteManagedRepositoryService.new(repository) }

  let(:config)   { {} }

  before do
    allow(OpenProject::Configuration).to receive(:[]).and_call_original
    allow(OpenProject::Configuration).to receive(:[]).with('scm').and_return(config)
  end

  shared_examples 'does not delete the repository' do
    it 'does not delete the repository' do
      expect(repository.managed?).to be false
      expect(service.call).to be false
    end
  end

  context 'with no managed configuration' do
    it_behaves_like 'does not delete the repository'
  end

  context 'with managed repository, but no config' do
    let(:repository) { FactoryGirl.build(:repository_subversion, scm_type: :managed) }

    it 'does not delete the repository' do
      expect(repository.managed?).to be true
      expect(service.call).to be false
    end
  end

  context 'with managed repository and managed config' do
    include_context 'with tmpdir'
    let(:config) {
      {
        Subversion: { manages: File.join(tmpdir, 'svn') },
        Git:        { manages: File.join(tmpdir, 'git') }
      }
    }

    # Must not .create a managed repository, or it will call this service itself!
    let(:repository) {
      repo = Repository::Subversion.new(scm_type: :managed)
      repo.project = project
      repo.configure(:managed, nil)

      repo.save!
      repo
    }

    before do
      allow_any_instance_of(Scm::CreateRepositoryJob)
        .to receive(:repository).and_return(repository)
    end

    it 'deletes the repository' do
      expect(File.directory?(repository.managed_repository_path)).to be true
      expect(service.call).to be true
      expect(File.directory?(repository.managed_repository_path)).to be false
    end

    context 'and parent project' do
      let(:parent) { FactoryGirl.create(:project) }
      let(:project) { FactoryGirl.create(:project, parent: parent) }
      let(:repo_path) {
        Pathname.new(File.join(tmpdir, 'svn', parent.identifier, "#{project.identifier}.svn"))
      }

      it 'deletes the parent path when empty' do
        expect(service.call).to be true
        path = Pathname.new(repository.managed_repository_path)
        expect(path).to eq(repo_path)

        expect(path.exist?).to be false
        expect(path.parent.exist?).to be false
      end

      it 'keeps the parent path when not empty' do
        other_repo = repo_path.parent + 'foobar'
        other_repo.mkdir

        expect(service.call).to be true
        expect(repo_path.exist?).to be false
        expect(repo_path.parent.exist?).to be true
      end
    end
  end
end
