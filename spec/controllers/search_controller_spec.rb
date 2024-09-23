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

RSpec.describe SearchController do
  shared_let(:project) do
    create(:project,
           name: "eCookbook")
  end

  shared_let(:other_project) do
    create(:project,
           name: "Other project")
  end

  shared_let(:subproject) do
    create(:project,
           name: "Child project",
           parent: project)
  end

  shared_let(:role) do
    create(:project_role, permissions: %i[view_wiki_pages view_work_packages])
  end

  shared_let(:user) do
    create(:user, member_with_roles: { project => role, subproject => role })
  end

  shared_let(:wiki_page) do
    create(:wiki_page,
           title: "How to solve an issue",
           wiki: project.wiki)
  end

  shared_let(:work_package_1) do
    create(:work_package,
           subject: "This is a test issue",
           project:)
  end

  shared_let(:work_package_2) do
    create(:work_package,
           subject: "Issue test 2",
           project:,
           status: create(:closed_status))
  end

  shared_let(:work_package_3) do
    create(:work_package,
           subject: "Issue test 3",
           project: subproject)
  end

  shared_let(:work_package_4) do
    create(:work_package,
           subject: "Issue test 4",
           project: other_project)
  end

  shared_examples_for "successful search" do
    it { expect(response).to be_successful }
    it { expect(response).to render_template("index") }
  end

  before { allow(User).to receive(:current).and_return user }

  describe "project search" do
    context "without a search parameter" do
      before { get :index }

      it_behaves_like "successful search"
    end

    context "search parameter" do
      context "is a search string" do
        before do
          get :index, params: { q: "cook" }
        end

        it_behaves_like "successful search"
      end
    end
  end

  describe "scoped project search" do
    before { get :index, params: { project_id: project.id } }

    it_behaves_like "successful search"

    it { expect(assigns(:project).id).to be(project.id) }
  end

  describe "searching in all modules" do
    context "when searching in all projects" do
      before { get :index, params: { q: "issue", scope: "all" } }

      it_behaves_like "successful search"

      describe "#result" do
        it { expect(assigns(:results).count).to be(4) }
        it { expect(assigns(:results)).to include(work_package_1) }
        it { expect(assigns(:results)).to include(work_package_2) }
        it { expect(assigns(:results)).to include(work_package_3) }
        it { expect(assigns(:results)).to include(wiki_page) }
        it { expect(assigns(:results)).not_to include(work_package_4) }
      end

      describe "#results_count" do
        it { expect(assigns(:results_count)).to be_a(Hash) }
        it { expect(assigns(:results_count)["work_packages"]).to be(3) }
      end
    end

    context "when searching in all projects with an untransliterable character" do
      before do
        work_package_1.update_column(:subject, "Something 会议 something")
        get :index, params: { q: "会议", scope: "all" }
      end

      it_behaves_like "successful search"

      it "returns the result", :aggregate_failures do
        expect(assigns(:results).count).to be(1)
        expect(assigns(:results)).to include(work_package_1)
        expect(assigns(:results_count)).to be_a(Hash)
        expect(assigns(:results_count)["work_packages"]).to be(1)
      end
    end

    context "when searching in project and its subprojects" do
      before { get :index, params: { q: "issue", project_id: project.id, scope: "subprojects" } }

      it_behaves_like "successful search"

      describe "#result" do
        it { expect(assigns(:results).count).to be(4) }
        it { expect(assigns(:results)).to include(work_package_1) }
        it { expect(assigns(:results)).to include(work_package_2) }
        it { expect(assigns(:results)).to include(work_package_3) }
        it { expect(assigns(:results)).to include(wiki_page) }
        it { expect(assigns(:results)).not_to include(work_package_4) }
      end
    end

    context "when searching in project without its subprojects" do
      before { get :index, params: { q: "issue", project_id: project.id, scope: "current_project" } }

      it_behaves_like "successful search"

      describe "#result" do
        it { expect(assigns(:results).count).to be(3) }
        it { expect(assigns(:results)).to include(work_package_1) }
        it { expect(assigns(:results)).to include(work_package_2) }
        it { expect(assigns(:results)).to include(wiki_page) }
        it { expect(assigns(:results)).not_to include(work_package_3) }
        it { expect(assigns(:results)).not_to include(work_package_4) }
      end
    end

    context "when searching for a note" do
      let!(:note_1) do
        create(:work_package_journal,
               journable_id: work_package_1.id,
               notes: "Test note 1",
               version: 2)
      end
      let!(:note_2) do
        create(:work_package_journal,
               journable_id: work_package_1.id,
               notes: "Special note 2",
               version: 3)
      end

      before do
        get :index, params: { q: "note" }
      end

      describe "second note predecessor" do
        subject { note_2.send :predecessor }

        it { is_expected.to eq note_1 }
        it { expect(note_1.data).not_to be_nil }
        it { expect(subject.data).not_to be_nil }
      end

      it_behaves_like "successful search"

      describe "#result" do
        it { expect(assigns(:results).count).to be 1 }

        it { expect(assigns(:results)).to include work_package_1 }

        it { expect(assigns(:tokens)).to include "note" }
      end
    end
  end

  describe "helper methods" do
    describe "#scan_query_tokens" do
      subject { @controller.send(:scan_query_tokens, query) }

      context "with one token" do
        let(:query) { "word" }

        it { is_expected.to eq %w(word) }

        context "with double quotes" do
          let(:query) { '"hello world"' }

          it { is_expected.to eq ["hello world"] }
        end
      end

      context "with multiple tokens" do
        let(:query) { "hello world something-hyphenated" }

        it { is_expected.to eq %w(hello world something-hyphenated) }

        context "with double quotes" do
          let(:query) { 'hello "fallen world" something-hyphenated' }

          it { is_expected.to eq ["hello", "fallen world", "something-hyphenated"] }
        end
      end
    end
  end
end
