# frozen_string_literal: true

require "spec_helper"
require "features/page_objects/notification"
require "support/components/autocompleter/ng_select_autocomplete_helpers"

RSpec.describe "Duplicate work packages through Rails view", :js do
  include Components::Autocompleter::NgSelectAutocompleteHelpers

  shared_let(:type) { create(:type, name: "Bug") }
  shared_let(:type2) { create(:type, name: "Risk") }

  shared_let(:project) { create(:project, name: "Source", types: [type, type2]) }
  shared_let(:project2) { create(:project, name: "Target", types: [type, type2]) }

  shared_let(:dev) do
    create(:user,
           firstname: "Dev",
           lastname: "Guy",
           member_with_permissions: { project => %i[view_work_packages work_package_assigned] })
  end
  shared_let(:mover) do
    create(:user,
           firstname: "Manager",
           lastname: "Guy",
           member_with_permissions: {
             project => %i[view_work_packages copy_work_packages move_work_packages manage_subtasks assign_versions
                           add_work_packages],
             project2 => %i[view_work_packages copy_work_packages move_work_packages manage_subtasks assign_versions
                            add_work_packages]
           })
  end

  shared_let(:work_package) do
    create(:work_package,
           subject: "work_package",
           author: dev,
           project:,
           type:)
  end
  shared_let(:work_package2) do
    create(:work_package,
           subject: "work_package2",
           author: dev,
           project:,
           type:)
  end
  shared_let(:version) { create(:version, project: project2) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:context_menu) { Components::WorkPackages::ContextMenu.new }
  let(:notes) { Components::WysiwygEditor.new }

  before do
    login_as current_user
    wp_table.visit!
    expect_angular_frontend_initialized
    wp_table.expect_work_package_listed work_package, work_package2
  end

  describe "copying work packages" do
    before do
      # Select all work packages
      find("body").send_keys [:control, "a"]
    end

    context "with permission" do
      let(:current_user) { mover }
      let(:wp_table_target) { Pages::WorkPackagesTable.new(project2) }

      before do
        context_menu.open_for work_package
        context_menu.choose "Bulk duplicate"

        expect(page).to have_css("#new_project_id") # rubocop:disable RSpec/ExpectInHook

        wait_for_network_idle

        wait_for_turbo_stream do
          select_autocomplete page.find_test_selector("new_project_id"),
                              query: project2.name,
                              select_text: project2.name,
                              results_selector: "body"
        end
      end

      it "sets the version on duplicate and leaves a note" do
        select version.name, from: "target_version_ids"
        notes.set_markdown "A note on duplicate"
        click_on "Duplicate and follow"

        wp_table_target.expect_current_path
        wp_table_target.expect_work_package_count 2
        expect(page).to have_css("#projects-menu", text: "Target")

        # Should not move the sources
        work_package2.reload
        work_package.reload

        # Check project of last two created wps
        copied_wps = WorkPackage.last(2)
        expect(copied_wps.map(&:project_id).uniq).to eq([project2.id])
        expect(copied_wps.map { |wp| wp.target_versions.pluck(:id) }.uniq).to eq([[version.id]])
        expect(copied_wps.map { |wp| wp.journals.last.notes }.uniq).to eq(["A note on duplicate"])
      end

      context "when the limit to move in the frontend is reached",
              with_settings: { work_packages_bulk_request_limit: 1 } do
        it "copies them in the background and shows a status page" do
          select version.name, from: "target_version_ids"
          notes.set_markdown "A note on duplicate"
          click_on "Duplicate and follow"

          expect(page).to have_text("The job has been queued and will be processed shortly.", wait: 10)

          perform_enqueued_jobs

          wp_table_target.expect_current_path
          wp_table_target.expect_work_package_count 2
        end
      end

      context "with hierarchies and relations" do
        shared_let(:child) do
          create(:work_package,
                 subject: "child",
                 author: dev,
                 project:,
                 type:,
                 parent: work_package)
        end
        shared_let(:child2) do
          create(:work_package,
                 subject: "child2",
                 author: dev,
                 project:,
                 type:,
                 parent: work_package2)
        end
        let!(:relation) do
          create(:relation,
                 from: child,
                 to: child2,
                 relation_type: Relation::TYPE_RELATES)
        end

        before do
          # make work_package and child be parent/child with automatically scheduled parent
          work_package.update(
            subject: "work_package parent",
            start_date: "2025-05-22", due_date: "2025-05-23", duration: 2,
            schedule_manually: false
          )
          child.update(
            start_date: "2025-05-22", due_date: "2025-05-23", duration: 2,
            schedule_manually: true
          )

          # make work_package2 and child2 be parent/child with manually scheduled parent
          work_package2.update(
            subject: "work_package2 parent",
            start_date: "2025-05-21", due_date: "2025-05-26", duration: 6,
            schedule_manually: true
          )
          child2.update(
            start_date: "2025-05-23", due_date: "2025-05-23", duration: 1,
            schedule_manually: true
          )
        end

        it "copies WPs with parent/child hierarchy and relations maintained, " \
           "as well as dates and scheduling modes" do
          click_on "Duplicate and follow"

          wp_table_target.expect_current_path
          expect(page).to have_css("#projects-menu", text: "Target")

          # Should not move the sources
          expect(work_package.reload.project_id).to eq(project.id)
          expect(work_package2.reload.project_id).to eq(project.id)
          expect(child.reload.project_id).to eq(project.id)
          expect(child2.reload.project_id).to eq(project.id)

          # Check target project contains the copied work packages
          expect_work_packages(project2.reload.work_packages, <<~TABLE)
            | hierarchy            | start date | due date   | duration | scheduling mode |
            | work_package parent  | 2025-05-22 | 2025-05-23 |        2 | automatic       |
            |   child              | 2025-05-22 | 2025-05-23 |        2 | manual          |
            | work_package2 parent | 2025-05-21 | 2025-05-26 |        6 | manual          |
            |   child2             | 2025-05-23 | 2025-05-23 |        1 | manual          |
          TABLE

          new_child = project2.work_packages.find_by(subject: child.subject)
          new_child2 = project2.work_packages.find_by(subject: child2.subject)

          expect(new_child.relations.count).to eq 1
          expect(new_child.relations.first).to have_attributes(
            relation_type: relation.relation_type,
            to_id: new_child2.id
          )
        end
      end

      context "with predecessor-successor relations" do
        shared_let(:work_package3) do
          create(:work_package,
                 author: dev,
                 project:,
                 type:)
        end
        let!(:relation_to_successor_automatic) do
          create(:follows_relation,
                 predecessor: work_package,
                 successor: work_package2)
        end
        let!(:relation_to_successor_manual) do
          create(:follows_relation,
                 predecessor: work_package,
                 successor: work_package3)
        end

        before do
          work_package.update(
            subject: "predecessor",
            start_date: "2025-05-20", due_date: "2025-05-21", duration: 2,
            schedule_manually: true
          )
          work_package2.update(
            subject: "successor automatic",
            start_date: "2025-05-22", due_date: "2025-05-23", duration: 2,
            schedule_manually: false
          )
          work_package3.update(
            subject: "successor manual",
            start_date: "2025-05-28", due_date: "2025-05-28", duration: 1,
            schedule_manually: true
          )
        end

        it "copies WPs with relations maintained, " \
           "as well as dates and scheduling modes" do
          click_on "Duplicate and follow"

          wp_table_target.expect_current_path
          expect(page).to have_css("#projects-menu", text: "Target")

          # Check target project contains the copied work packages
          expect_work_packages(project2.reload.work_packages, <<~TABLE)
            | subject             | start date | due date   | duration | scheduling mode |
            | predecessor         | 2025-05-20 | 2025-05-21 |        2 | manual          |
            | successor automatic | 2025-05-22 | 2025-05-23 |        2 | automatic       |
            | successor manual    | 2025-05-28 | 2025-05-28 |        1 | manual          |
          TABLE

          new_predecessor = project2.work_packages.find_by(subject: work_package.subject)

          expect(new_predecessor.relations.count).to eq 2
          expect(new_predecessor.relations)
            .to all(have_attributes(
                      relation_type: Relation::TYPE_FOLLOWS,
                      to_id: new_predecessor.id
                    ))
        end
      end

      context "when the target project does not have the type" do
        let!(:child) do
          create(:work_package,
                 author: dev,
                 project:,
                 type:,
                 parent: work_package)
        end

        before do
          project2.project_types = [ProjectType.new(type: type2)]
        end

        it "fails, informing of the reasons" do
          click_on "Duplicate and follow"

          expect_flash(type: :error, message: I18n.t("work_packages.bulk.none_could_be_saved", total: 3))
          expect_flash(type: :error,
                       message: I18n.t(
                         "work_packages.bulk.selected_because_descendants", total: 3, selected: 2
                       ))
          expect_flash(type: :error,
                       message: "#{work_package.id}: Type #{I18n.t('activerecord.errors.messages.inclusion')}")
          expect_flash(type: :error,
                       message: "#{work_package2.id}: Type #{I18n.t('activerecord.errors.messages.inclusion')}")
          expect_flash(type: :error, message:
            "#{child.id} (descendant of selected): Type #{I18n.t('activerecord.errors.messages.inclusion')}")
        end

        context "when the limit to move in the frontend is 0",
                with_settings: { work_packages_bulk_request_limit: 0 } do
          it "shows the errors properly in the frontend" do
            click_on "Duplicate and follow"

            expect(page).to have_text "The job has been queued and will be processed shortly."

            perform_enqueued_jobs

            expect(page).to have_text "The work packages could not be copied.", wait: 10

            expect(page).to have_text I18n.t("work_packages.bulk.none_could_be_saved", total: 3)

            expect(page)
              .to have_text I18n.t("work_packages.bulk.selected_because_descendants", total: 3, selected: 2)

            expect(page)
              .to have_text "#{work_package.id}: Type #{I18n.t('activerecord.errors.messages.inclusion')}"

            expect(page)
              .to have_text "#{work_package2.id}: Type #{I18n.t('activerecord.errors.messages.inclusion')}"

            expect(page)
              .to have_text "#{child.id} (descendant of selected): Type #{I18n.t('activerecord.errors.messages.inclusion')}"
          end
        end
      end
    end

    context "without permission" do
      let(:current_user) { dev }

      it "does not allow to duplicate work packages" do
        context_menu.open_for work_package, check_if_open: false
        context_menu.expect_closed
      end
    end
  end

  describe "unsetting the assignee as the current assignee is not a member in the project" do
    let(:work_packages) { [work_package] }
    let(:current_user) { mover }
    let(:wp_table) { Pages::WorkPackagesTable.new(project) }

    before do
      work_package.assigned_to = dev
      work_package.save
    end

    it "duplicates the work package" do
      context_menu.open_for work_package
      context_menu.choose "Duplicate in another project"

      # On work packages move page
      wait_for_turbo_stream do
        select_autocomplete page.find_test_selector("new_project_id"),
                            query: project2.name,
                            select_text: project2.name,
                            results_selector: "body"
      end

      select "nobody", from: "Assignee"

      click_on "Duplicate and follow"

      expect_flash(message: I18n.t(:notice_successful_create))

      wp_page = Pages::FullWorkPackage.new(WorkPackage.last)

      wp_page.expect_attributes assignee: "-"
    end
  end
end
