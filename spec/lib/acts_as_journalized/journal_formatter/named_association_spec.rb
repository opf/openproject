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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe JournalFormatter::NamedAssociation do
  shared_let(:permitted_project) { create(:private_project, name: "Permitted project") }
  shared_let(:other_project) { create(:private_project, name: "Other project") }

  shared_let(:permitted_parent) do
    create(:work_package, project: permitted_project, subject: "Parent in permitted project")
  end
  shared_let(:other_parent) do
    create(:work_package, project: other_project, subject: "Parent in other project")
  end

  shared_let(:reader) do
    create(:user, member_with_permissions: { permitted_project => %i[view_work_packages view_project_activity] })
  end
  shared_let(:reader_of_both) do
    create(:user, member_with_permissions: {
             permitted_project => %i[view_work_packages view_project_activity],
             other_project => %i[view_work_packages view_project_activity]
           })
  end

  describe "the parent of a work package" do
    shared_let(:work_package) { create(:work_package, project: permitted_project, subject: "Child") }

    let(:journal) { work_package.journals.last }

    def render(values)
      journal.render_detail(["parent_id", values])
    end

    context "with a reader permitted in one project only" do
      current_user { reader }

      it "names the parent it may see" do
        expect(render([nil, permitted_parent.id])).to include(permitted_parent.subject)
        expect(render([permitted_parent.id, nil])).to include(permitted_parent.subject)
      end

      it "withholds the subject of the parent it may not see" do
        expect(render([nil, other_parent.id]))
          .to eq("<strong>Parent</strong> set to <i>a non-visible work package</i>")
        expect(render([other_parent.id, nil])).not_to include(other_parent.subject)
        expect(render([other_parent.id, permitted_parent.id])).not_to include(other_parent.subject)
        expect(render([permitted_parent.id, other_parent.id])).not_to include(other_parent.subject)
      end
    end

    # Verdicts are memoized per request. Should a thread ever outlive one, the next
    # reader must still be judged on their own access.
    it "does not carry one reader's verdict over to the next" do
      login_as(reader)
      withheld = render([nil, other_parent.id])

      login_as(reader_of_both)
      disclosed = render([nil, other_parent.id])

      expect(withheld).not_to include(other_parent.subject)
      expect(disclosed).to include(other_parent.subject)
    end

    context "with a reader permitted in both projects" do
      current_user { reader_of_both }

      it "names both parents" do
        expect(render([permitted_parent.id, other_parent.id]))
          .to include(permitted_parent.subject)
          .and include(other_parent.subject)
      end
    end

    context "with a journal written by an actual parent change",
            with_settings: { journal_aggregation_time_minutes: 0 } do
      shared_let(:child) { create(:work_package, project: permitted_project, subject: "Reparented") }

      shared_let(:parent_change_journal) do
        User.execute_as(create(:admin)) do
          WorkPackages::UpdateService.new(user: User.current, model: child).call(parent: other_parent)
        end

        child.reload.journals.last
      end

      current_user { reader }

      it "withholds the subject across every detail of the journal" do
        expect(parent_change_journal.details).to include("parent_id")

        rendered = parent_change_journal.details.keys.filter_map { parent_change_journal.render_detail(it) }

        expect(rendered).to be_present
        expect(rendered.join(" ")).not_to include(other_parent.subject)
      end
    end
  end

  describe "the project of a work package" do
    shared_let(:work_package) { create(:work_package, project: permitted_project, subject: "Moved") }

    let(:journal) { work_package.journals.last }

    def render(values)
      journal.render_detail(["project_id", values])
    end

    context "with a reader permitted in one project only" do
      current_user { reader }

      it "withholds the name of the project it may not see" do
        expect(render([other_project.id, permitted_project.id]))
          .to eq("<strong>Project</strong> changed from <i>a non-visible project</i> " \
                 "to <i>#{permitted_project.name}</i>")
      end
    end

    context "with a reader permitted in both projects" do
      current_user { reader_of_both }

      it "names both projects" do
        expect(render([other_project.id, permitted_project.id]))
          .to include(other_project.name)
          .and include(permitted_project.name)
      end
    end
  end

  describe "the parent of a project" do
    let(:journal) { permitted_project.journals.last }

    def render(values)
      journal.render_detail(["parent_id", values])
    end

    context "with a reader permitted in one project only" do
      current_user { reader }

      it "withholds the name of the parent project it may not see" do
        expect(render([nil, other_project.id])).not_to include(other_project.name)
      end

      # The wording the project activity page shows when a subproject is detached
      # from a parent the reader has no access to.
      it "withholds the name of a parent it no longer belongs to" do
        expect(render([other_project.id, nil]))
          .to eq("<strong>No longer subproject of</strong> <i>a non-visible project</i>")
      end
    end

    context "with a reader permitted in both projects" do
      current_user { reader_of_both }

      it "names the parent project" do
        expect(render([nil, other_project.id])).to include(other_project.name)
      end
    end
  end

  # Moving a work package between projects nulls its version, category and budget
  # and reassigns its category, so one journal entry can name several records that
  # belong to the project it came from.
  describe "records left behind by a move between projects" do
    shared_let(:work_package) { create(:work_package, project: permitted_project, subject: "Moved") }

    shared_let(:other_version) { create(:version, project: other_project, name: "Version in other project") }
    shared_let(:other_category) { create(:category, project: other_project, name: "Category in other project") }
    shared_let(:other_budget) { create(:budget, project: other_project, subject: "Budget in other project") }

    let(:journal) { work_package.journals.last }

    context "with a reader permitted in one project only" do
      current_user { reader }

      it "withholds the version name" do
        expect(journal.render_detail(["version_id", [other_version.id, nil]]))
          .to eq("<strong>Version</strong> deleted (<strike><i>a non-visible version</i></strike>)")
      end

      it "withholds the category name" do
        expect(journal.render_detail(["category_id", [other_category.id, nil]]))
          .not_to include(other_category.name)
      end

      it "withholds the budget name" do
        expect(journal.render_detail(["budget_id", [other_budget.id, nil]]))
          .not_to include(other_budget.subject)
      end

      it "withholds names among the target versions" do
        permitted_version = create(:version, project: permitted_project, name: "Version in permitted project")
        rendered = journal.render_detail(["target_versions", [nil, "#{permitted_version.id},#{other_version.id}"]])

        expect(rendered).to include(permitted_version.name)
        expect(rendered).not_to include(other_version.name)
      end
    end

    context "with a reader permitted in both projects" do
      current_user { reader_of_both }

      it "names all of them" do
        expect(journal.render_detail(["version_id", [other_version.id, nil]])).to include(other_version.name)
        expect(journal.render_detail(["category_id", [other_category.id, nil]])).to include(other_category.name)
        expect(journal.render_detail(["budget_id", [other_budget.id, nil]])).to include(other_budget.subject)
      end
    end
  end

  describe "people, which the journable names anyway" do
    shared_let(:work_package) { create(:work_package, project: permitted_project, subject: "Assigned") }
    shared_let(:stranger) do
      create(:user, firstname: "Stranger", lastname: "Person",
                    member_with_permissions: { other_project => %i[view_work_packages] })
    end

    let(:journal) { work_package.journals.last }

    current_user { reader }

    it "names them even though the reader shares no project with them" do
      expect(stranger.visible?(reader)).to be(false)

      expect(journal.render_detail(["assigned_to_id", [nil, stranger.id]])).to include(stranger.name)
      expect(journal.render_detail(["responsible_id", [nil, stranger.id]])).to include(stranger.name)
      expect(journal.render_detail(["author_id", [nil, stranger.id]])).to include(stranger.name)
    end
  end
end
