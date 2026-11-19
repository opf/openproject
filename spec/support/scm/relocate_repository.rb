# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

RSpec.shared_examples_for "repository can be relocated" do |vendor|
  let(:job_call) do
    SCM::RelocateRepositoryJob.perform_now repository
  end
  let(:project) { build(:project) }
  let(:repository) do
    repo = build(:"repository_#{vendor}",
                 project:,
                 scm_type: :managed)

    repo.configure(:managed, nil)
    repo.save!
    perform_enqueued_jobs

    repo
  end

  before do
    allow(Repository).to receive(:find).and_return(repository)
  end

  needed_command = "svnadmin" if vendor == :subversion

  context "with managed local config", skip_if_command_unavailable: needed_command do
    include_context "with tmpdir"
    let(:config) { { manages: File.join(tmpdir, "myrepos") } }

    it "relocates when project identifier is updated" do
      current_path = repository.root_url
      expect(repository.root_url).to eq(repository.managed_repository_path)
      expect(Dir.exist?(repository.managed_repository_path)).to be true

      # Rename the project
      project.update!(identifier: "somenewidentifier")
      repository.reload

      job_call

      # Confirm that all paths are updated
      expect(current_path).not_to eq(repository.managed_repository_path)
      expect(current_path).not_to eq(repository.root_url)
      expect(repository.url).to eq(repository.managed_repository_url)

      expect(Dir.exist?(repository.managed_repository_path)).to be true
    end
  end

  context "with managed remote config", :webmock do
    let(:url) { "http://myreposerver.example.com/api/" }
    let(:config) { { manages: url } }

    let(:repository) do
      stub_request(:post, url)
        .to_return(status: 200,
                   body: { success: true, url: "file:///foo/bar", path: "/tmp/foo/bar" }.to_json)
      create(:"repository_#{vendor}",
             project:,
             scm_type: :managed)
    end

    before do
      stub_request(:post, url)
        .to_return(status: 200,
                   body: { success: true, url: "file:///new/bar", path: "/tmp/new/bar" }.to_json)
    end

    it "sends a relocation request when project identifier is updated" do
      old_identifier = "bar"

      # Rename the project
      project.identifier = "somenewidentifier"

      job_call

      expect(WebMock)
        .to have_requested(:post, url)
        .with(body: hash_including(old_identifier:,
                                   action: "relocate"))
    end
  end
end
