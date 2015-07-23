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

describe Scm::CreateManagedRepositoryService do
  let(:user) { FactoryGirl.build(:user) }
  let(:project) { FactoryGirl.build(:project) }

  let(:repository) { FactoryGirl.build(:repository_subversion) }
  subject(:service) { Scm::CreateManagedRepositoryService.new(repository) }

  let(:config)   { {} }

  before do
    allow(OpenProject::Configuration).to receive(:[]).and_call_original
    allow(OpenProject::Configuration).to receive(:[]).with('scm').and_return(config)
  end

  shared_examples 'does not create a filesystem repository' do
    it 'does not create a filesystem repository' do
      expect(repository.managed?).to be false
      expect(service.call).to be false
    end
  end

  context 'with no managed configuration' do
    it_behaves_like 'does not create a filesystem repository'
  end

  context 'with managed repository' do
    # Must not .create a managed repository, or it will call this service itself!
    let(:repository) {
      repo = Repository::Subversion.new(scm_type: :managed)
      repo.project = project
      repo
    }

    context 'but no managed config' do
      it 'does not create a filesystem repository' do
        expect(repository.managed?).to be true
        expect(service.call).to be false
      end
    end
  end

  context 'with managed config' do
    include_context 'with tmpdir'
    let(:config) {
      {
        Subversion: { manages: File.join(tmpdir, 'svn') },
        Git:        { manages: File.join(tmpdir, 'git') }
      }
    }

    let(:repository) {
      repo = Repository::Subversion.new(scm_type: :managed)
      repo.project = project
      repo.configure(:managed, nil)
      repo
    }

    before do
      allow_any_instance_of(Scm::CreateRepositoryJob)
        .to receive(:repository).and_return(repository)
    end

    it 'creates the repository' do
      expect(service.call).to be true
      expect(File.directory?(repository.managed_repository_path)).to be true
    end

    context 'with pre-existing path on filesystem' do
      before do
        allow(File).to receive(:directory?).and_return(true)
      end

      it 'does not create the repository' do
        expect(service.call).to be false
        expect(service.localized_rejected_reason)
          .to eq(I18n.t('repositories.errors.exists_on_filesystem'))
      end
    end
  end
end
