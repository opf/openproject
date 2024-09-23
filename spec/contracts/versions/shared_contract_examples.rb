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

RSpec.shared_examples_for "version contract" do
  let(:current_user) { build_stubbed(:user) }

  before do
    mock_permissions_for(current_user) do |mock|
      mock.allow_in_project(*permissions, project: version_project) if version_project
      mock.allow_in_project(*root_permissions, project: root_project) if root_project
    end
  end

  let(:root_project) { build_stubbed(:project) }
  let(:version_project) do
    build_stubbed(:project, wiki: project_wiki).tap do |p|
      allow(p)
        .to receive(:root)
        .and_return(root_project)
    end
  end
  let(:project_wiki) do
    build_stubbed(:wiki, pages: wiki_pages).tap do |wiki|
      allow(wiki)
        .to receive(:find_page)
        .with(version_wiki_page_title)
        .and_return(find_page_result)
    end
  end
  let(:find_page_result) do
    double("page found")
  end
  let(:wiki_pages) do
    [build_stubbed(:wiki_page),
     build_stubbed(:wiki_page)]
  end
  let(:version_name) { "Version name" }
  let(:version_description) { "Version description" }
  let(:version_start_date) { Date.current - 5.days }
  let(:version_due_date) { Date.current + 5.days }
  let(:version_status) { "open" }
  let(:version_sharing) { "none" }
  let(:version_wiki_page_title) { "some page" }
  let(:permissions) { [:manage_versions] }
  let(:root_permissions) { [:manage_versions] }

  context "validations" do
    def expect_valid(valid, symbols = {})
      expect(contract.validate).to eq(valid)

      symbols.each do |key, arr|
        expect(contract.errors.symbols_for(key)).to match_array arr
      end
    end

    shared_examples "is valid" do
      it "is valid" do
        expect_valid(true)
      end
    end

    it_behaves_like "is valid"

    context "if the project is nil" do
      let(:version_project) { nil }

      it "is invalid" do
        expect_valid(false, project_id: %i(blank))
      end
    end

    context "if the name is nil" do
      let(:version_name) { nil }

      it "is invalid" do
        expect_valid(false, name: %i(blank))
      end
    end

    context "if the description is nil" do
      let(:version_description) { nil }

      it_behaves_like "is valid"
    end

    context "if the start_date is nil" do
      let(:version_start_date) { nil }

      it_behaves_like "is valid"
    end

    context "if the end_date is nil" do
      let(:version_due_date) { nil }

      it_behaves_like "is valid"
    end

    context "if the status is nil" do
      let(:version_status) { nil }

      it "is invalid" do
        expect_valid(false, status: %i(inclusion))
      end
    end

    context "if the status is something other than the allowed values" do
      let(:version_status) { "other_status" }

      it "is invalid" do
        expect_valid(false, status: %i(inclusion))
      end
    end

    context "if sharing is nil" do
      before do
        version.sharing = "nil"
      end

      it "is invalid" do
        expect_valid(false, sharing: %i(inclusion))
      end
    end

    context "if sharing is bogus" do
      before do
        version.sharing = "bogus"
      end

      it "is invalid" do
        expect_valid(false, sharing: %i(inclusion))
      end
    end

    context "if sharing is system and the user an admin" do
      let(:current_user) { build_stubbed(:admin) }

      before do
        version.sharing = "system"
      end

      it_behaves_like "is valid"
    end

    context "if sharing is system and the user no admin" do
      before do
        version.sharing = "system"
      end

      it "is invalid" do
        expect_valid(false, sharing: %i(inclusion))
      end
    end

    context "if sharing is descendants" do
      before do
        version.sharing = "descendants"
      end

      it_behaves_like "is valid"
    end

    context "if sharing is tree and the user has manage permission on the root project" do
      before do
        version.sharing = "tree"
      end

      it_behaves_like "is valid"
    end

    context "if sharing is tree and the user has no manage permission on the root project" do
      let(:root_permissions) { [] }

      before do
        version.sharing = "tree"
      end

      it "is invalid" do
        expect_valid(false, sharing: %i(inclusion))
      end
    end

    context "if sharing is hierarchy and the user has manage permission on the root project" do
      before do
        version.sharing = "hierarchy"
      end

      it_behaves_like "is valid"
    end

    context "if sharing is hierarchy and the user has no manage permission on the root project" do
      let(:root_permissions) { [] }

      before do
        version.sharing = "hierarchy"
      end

      it "is invalid" do
        expect_valid(false, sharing: %i(inclusion))
      end
    end

    context "if the user lacks the manage_versions permission" do
      let(:permissions) { [] }

      it "is invalid" do
        expect_valid(false, base: %i(error_unauthorized))
      end
    end

    context "if the start date is after the effective date" do
      let(:version_start_date) { version_due_date + 1.day }

      it "is invalid" do
        expect_valid(false, effective_date: %i(greater_than_start_date))
      end
    end

    context "if wiki_page_title is nil" do
      let(:version_wiki_page_title) { nil }
      let(:find_page_result) do
        nil
      end

      it_behaves_like "is valid"
    end

    context "if wiki_page_title is blank" do
      let(:version_wiki_page_title) { "" }
      let(:find_page_result) do
        nil
      end

      it_behaves_like "is valid"
    end

    context "if wiki_page_title contains a non existing page" do
      let(:version_wiki_page_title) { "http://some/url/i/made/up" }
      let(:find_page_result) do
        nil
      end

      it "is invalid" do
        expect_valid(false, wiki_page_title: %i(inclusion))
      end
    end
  end

  describe "assignable values" do
    describe "assignable_wiki_pages" do
      context "with a wiki assigned" do
        it "returns the pages of the project`s wiki" do
          expect(contract.assignable_wiki_pages)
            .to match_array(wiki_pages)
        end
      end

      context "without a wiki assigned" do
        let(:project_wiki) { nil }

        it "is empty" do
          expect(contract.assignable_wiki_pages)
            .to be_empty
        end
      end
    end
  end
end
