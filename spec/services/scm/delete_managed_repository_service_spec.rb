#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

require 'spec_helper'

describe SCM::DeleteManagedRepositoryService do
  let(:user) { FactoryBot.build(:user) }
  let(:project) { FactoryBot.build(:project) }

  let(:repository) { FactoryBot.build(:repository_subversion) }
  subject(:service) { SCM::DeleteManagedRepositoryService.new(repository) }

  let(:config) { {} }

  before do
    allow(OpenProject::Configuration).to receive(:[]).and_call_original
    allow(OpenProject::Configuration).to receive(:[]).with('scm').and_return(config)
    allow(Setting).to receive(:enabled_scm).and_return(['subversion', 'git'])
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
    let(:repository) { FactoryBot.build(:repository_subversion, scm_type: :managed) }

    it 'does allow to delete the repository' do
      expect(repository.managed?).to be true
      expect(service.call).to be true
    end
  end

  context 'with managed repository and managed config' do
    include_context 'with tmpdir'
    let(:config) {
      {
        subversion: { manages: File.join(tmpdir, 'svn') },
        git: { manages: File.join(tmpdir, 'git') }
      }
    }

    let(:repository) {
      repo = Repository::Subversion.new(scm_type: :managed)
      repo.project = project
      repo.configure(:managed, nil)

      repo.save!
      perform_enqueued_jobs
      repo
    }

    it 'deletes the repository' do
      expect(File.directory?(repository.root_url)).to be true
      expect(service.call).to be true
      expect(File.directory?(repository.root_url)).to be false
    end

    it 'does not raise an exception upon permission errors' do
      expect(File.directory?(repository.root_url)).to be true
      expect(SCM::DeleteLocalRepositoryJob)
        .to receive(:new).and_raise(Errno::EACCES)

      expect(service.call).to be false
    end

    context 'and parent project' do
      let(:parent) { FactoryBot.create(:project) }
      let(:project) { FactoryBot.create(:project, parent: parent) }
      let(:repo_path) {
        Pathname.new(File.join(tmpdir, 'svn', project.identifier))
      }

      it 'does not delete anything but the repository itself' do
        expect(service.call).to be true

        path = Pathname.new(repository.root_url)
        expect(path).to eq(repo_path)

        expect(path.exist?).to be false
        expect(path.parent.exist?).to be true
        expect(path.parent.to_s).to eq(repository.class.managed_root)
      end
    end
  end

  context 'with managed remote config', webmock: true do
    let(:url) { 'http://myreposerver.example.com/api/' }
    let(:config) {
      {
        subversion: { manages: url }
      }
    }

    let(:repository) {
      repo = Repository::Subversion.new(scm_type: :managed)
      repo.project = project
      repo.configure(:managed, nil)

      repo
    }

    context 'with a valid remote' do
      before do
        stub_request(:post, url).to_return(status: 200, body: {}.to_json )
      end

      it 'calls the callback' do
        expect(::SCM::DeleteRemoteRepositoryJob)
          .to receive(:perform_now)
          .and_call_original

        expect(service.call).to be true
        expect(WebMock)
          .to have_requested(:post, url)
          .with(body: hash_including(identifier: repository.repository_identifier,
                                     action: 'delete'))
      end
    end

    context 'with a remote callback returning an error' do
      before do
        stub_request(:post, url)
          .to_return(status: 400, body: { success: false, message: 'An error occurred' }.to_json)
      end

      it 'calls the callback' do
        expect(::SCM::DeleteRemoteRepositoryJob)
          .to receive(:perform_now)
          .and_call_original


        expect(service.call).to be false

        expect(service.localized_rejected_reason)
          .to eq("Calling the managed remote failed with message 'An error occurred' (Code: 400)")
        expect(WebMock)
          .to have_requested(:post, url)
                .with(body: hash_including(action: 'delete'))
      end
    end
  end
end
