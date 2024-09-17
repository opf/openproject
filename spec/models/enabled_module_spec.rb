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

RSpec.describe EnabledModule do
  # Force reload, as association is not always(?) showing
  let(:project) { create(:project, enabled_module_names: modules).reload }

  describe "#wiki" do
    let(:modules) { %w[wiki] }

    it "creates a wiki" do
      expect(project.wiki).not_to be_nil
      expect(project.wiki.start_page).to eq("Wiki")
    end

    it "does not create a separate wiki when one exists already" do
      expect(project.wiki).not_to be_nil

      expect do
        project.enabled_module_names = []
        project.reload
      end.not_to change { Wiki.count }

      expect do
        project.enabled_module_names = ["wiki"]
      end.not_to change { Wiki.count }

      expect(project.wiki).not_to be_nil
    end

    context "with disabled module" do
      let(:modules) { [] }

      it "does not create a wiki" do
        expect(project.wiki).to be_nil
      end

      it "creates a wiki when the module is enabled at a later time" do
        project.enabled_module_names = ["wiki"]
        project.reload

        expect(project.wiki).not_to be_nil
        expect(project.wiki.start_page).to eq("Wiki")
      end
    end
  end

  describe "#repository" do
    let(:modules) { %w[repository] }

    before do
      allow(Setting).to receive(:repositories_automatic_managed_vendor).and_return(vendor)
    end

    shared_examples "does not create a repository when one exists" do
      let!(:repository) { create(:repository_git, project:) }

      it "does not create a separate repository when one exists already" do
        project.reload
        expect(project.repository).not_to be_nil

        expect do
          project.enabled_module_names = []
          project.reload
        end.not_to change { Repository.count }

        expect do
          project.enabled_module_names = ["repository"]
        end.not_to change { Repository.count }

        expect(project.repository).not_to be_nil
      end
    end

    context "with disabled setting" do
      let(:vendor) { nil }

      it "does not create a repository" do
        expect(project.repository).to be_nil
      end

      it_behaves_like "does not create a repository when one exists"
    end

    context "with enabled setting" do
      let(:vendor) { "git" }
      let(:config) do
        {
          git: { manages: File.join(tmpdir, "git") }
        }
      end

      include_context "with tmpdir"

      before do
        allow(Setting).to receive(:enabled_scm).and_return(["git"])
        allow(OpenProject::Configuration).to receive(:[]).and_call_original
        allow(OpenProject::Configuration).to receive(:[]).with("scm").and_return(config)
      end

      it "creates a repository of the given vendor" do
        project.reload

        expect(project.repository).not_to be_nil
        expect(project.repository.vendor).to eq(:git)
        expect(project.repository.managed?).to be true
      end

      it "does not remove the repository when setting is removed" do
        project.enabled_module_names = []
        project.reload

        expect(project.repository).not_to be_nil
      end

      it_behaves_like "does not create a repository when one exists"
    end

    context "with invalid setting" do
      let(:vendor) { "some weird vendor" }

      it "does not create a repository" do
        expect(project.repository).to be_nil
      end
    end
  end
end
