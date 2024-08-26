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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe SCM::CreateLocalRepositoryJob do
  let(:instance) { described_class.new }
  # Allow to override configuration values to determine
  # whether to activate managed repositories
  let(:enabled_scms) { %w[subversion git] }
  let(:config) { nil }

  subject { instance.perform(repository) }

  before do
    allow(Setting).to receive(:enabled_scm).and_return(enabled_scms)

    allow(OpenProject::Configuration).to receive(:[]).and_call_original
    allow(OpenProject::Configuration).to receive(:[]).with("scm").and_return(config)
  end

  describe "with a managed repository", skip_if_command_unavailable: "svnadmin" do
    include_context "with tmpdir"

    let(:project) { build(:project) }
    let(:repository) do
      repo = Repository::Subversion.new(scm_type: :managed)
      repo.project = project
      repo.configure(:managed, nil)
      repo
    end

    let(:config) do
      { subversion: { mode:, manages: tmpdir } }
    end

    shared_examples "creates a directory with mode" do |expected|
      it "creates the directory" do
        subject
        expect(Dir.exist?(repository.root_url)).to be true

        file_mode = File.stat(repository.root_url).mode
        expect(sprintf("%o", file_mode)).to end_with(expected)
      end
    end

    context "with mode set" do
      let(:mode) { 0o770 }

      it "uses the correct mode" do
        expect(instance).to receive(:create).with(mode)
        subject
      end

      it_behaves_like "creates a directory with mode", "0770"
    end

    context "with string mode" do
      let(:mode) { "0770" }

      it "uses the correct mode" do
        expect(instance).to receive(:create).with(0o770)
        subject
      end

      it_behaves_like "creates a directory with mode", "0770"
    end

    context "with no mode set" do
      let(:mode) { nil }

      it "uses the default mode" do
        expect(instance).to receive(:create).with(0o700)
        subject
      end

      it_behaves_like "creates a directory with mode", "0700"
    end
  end
end
