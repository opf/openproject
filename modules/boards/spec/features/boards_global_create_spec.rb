# frozen_string_literal: true

require "spec_helper"
require_relative "support/board_new_page"

RSpec.describe "Boards",
               "Creating a view from a Global Context",
               :js,
               :with_cuprite,
               with_ee: %i[board_view] do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking board_view]) }
  shared_let(:other_project) { create(:project, enabled_module_names: %i[work_package_tracking board_view]) }
  shared_let(:admin) { create(:admin) }

  shared_let(:status) { create(:default_status) }
  shared_let(:versions) { create_list(:version, 3, project:) }
  shared_let(:excluded_versions) do
    [
      create(:version, project:, status: "closed"),
      create(:version, project: other_project, sharing: "system")
    ]
  end

  shared_let(:new_board_page) { Pages::NewBoard.new }

  before do
    login_as admin
  end

  context "within the global index page" do
    before do
      visit work_package_boards_path
    end

    context "when clicking on the create button" do
      before do
        new_board_page.navigate_by_create_button
      end

      it "navigates to the global create form" do
        expect(page).to have_current_path new_work_package_board_path
        expect(page).to have_content I18n.t("boards.label_create_new_board")
      end
    end
  end

  context "within the global create page" do
    before do
      new_board_page.visit!
    end

    context "with a Community Edition", with_ee: %i[] do
      it "renders an enterprise banner and disables all restricted board types", :aggregate_failures do
        expect(page).to have_enterprise_banner
        expect(page).to have_selector(:radio_button, "Basic")

        %w[Status Assignee Version Subproject Parent-child].each do |restricted_board_type|
          expect(page).to have_selector(:radio_button, restricted_board_type, disabled: true)
        end
      end
    end

    context "with an Enterprise Edition" do
      context "with all fields set" do
        before do
          wait_for_reload # Halt until the project autocompleter is ready

          new_board_page.set_title "Gotham Renewal Board"
          new_board_page.set_project project
        end

        context 'when creating a "Basic" board' do
          before do
            new_board_page.set_board_type "Basic"
            new_board_page.click_on_submit

            wait_for_reload
          end

          it "creates the board and redirects me to it" do
            expect(page).to have_text(I18n.t(:notice_successful_create))
            expect(page).to have_current_path("/projects/#{project.identifier}/boards/#{Boards::Grid.last.id}")
            expect(page).to have_text "Gotham Renewal Board"
          end
        end

        context 'when creating a "Status" board' do
          before do
            new_board_page.set_board_type "Status"
            new_board_page.click_on_submit

            wait_for_reload
          end

          it "creates the board and redirects me to it" do
            expect(page).to have_text(I18n.t(:notice_successful_create))
            expect(page).to have_current_path("/projects/#{project.identifier}/boards/#{Boards::Grid.last.id}")
            expect(page).to have_text "Gotham Renewal Board"
            expect(page).to have_css("[data-query-name='#{status.name}']")
          end
        end

        context 'when creating an "Assignee" board' do
          before do
            new_board_page.set_board_type "Assignee"
            new_board_page.click_on_submit

            wait_for_reload
          end

          it "creates the board and redirects me to it" do
            expect(page).to have_text(I18n.t(:notice_successful_create))
            expect(page).to have_current_path("/projects/#{project.identifier}/boards/#{Boards::Grid.last.id}")
            expect(page).to have_text "Gotham Renewal Board"
          end
        end

        context 'when creating a "Version" board' do
          before do
            new_board_page.set_board_type "Version"
            new_board_page.click_on_submit

            wait_for_reload
          end

          it "creates the board and redirects me to it", :aggregate_failures do
            expect(page).to have_text(I18n.t(:notice_successful_create))
            expect(page).to have_current_path("/projects/#{project.identifier}/boards/#{Boards::Grid.last.id}")
            expect(page).to have_text "Gotham Renewal Board"
            versions.each do |version|
              expect(page).to have_css("[data-query-name='#{version.name}'")
            end
            excluded_versions.each do |version|
              expect(page).to have_no_css("[data-query-name='#{version.name}'")
            end
          end
        end

        context 'when creating a "Subproject" board' do
          before do
            new_board_page.set_board_type "Subproject"
            new_board_page.click_on_submit

            wait_for_reload
          end

          it "creates the board and redirects me to it" do
            expect(page).to have_text(I18n.t(:notice_successful_create))
            expect(page).to have_current_path("/projects/#{project.identifier}/boards/#{Boards::Grid.last.id}")
            expect(page).to have_text "Gotham Renewal Board"
          end
        end

        context 'when creating a "Parent-child" board' do
          before do
            new_board_page.set_board_type "Parent-child"
            new_board_page.click_on_submit

            wait_for_reload
          end

          it "creates the board and redirects me to it" do
            expect(page).to have_text(I18n.t(:notice_successful_create))
            expect(page).to have_current_path("/projects/#{project.identifier}/boards/#{Boards::Grid.last.id}")
            expect(page).to have_text "Gotham Renewal Board"
          end
        end
      end

      context "when missing a required field" do
        describe "title" do
          before do
            wait_for_reload # Halt until the project autocompleter is ready

            new_board_page.set_project(project)
            new_board_page.click_on_submit
          end

          it "renders a required attribute validation error" do
            expect(Boards::Grid.all).to be_empty

            # Required HTML attribute just warns
            expect(page).to have_current_path(new_work_package_board_path)
          end
        end

        describe "project_id" do
          before do
            new_board_page.set_title("Batman's Itinerary")
            new_board_page.click_on_submit

            wait_for_reload
          end

          it "renders a required attribute validation error" do
            expect(Boards::Grid.all).to be_empty

            expect_flash message: "Project #{I18n.t('activerecord.errors.messages.blank')}",
                         type: :error

            new_board_page.expect_project_dropdown
          end
        end
      end
    end

    describe "cancel button" do
      context "when it's clicked" do
        before do
          new_board_page.click_on_cancel_button
        end

        it "navigates back to the global index page" do
          expect(page).to have_current_path(work_package_boards_path)
        end
      end
    end
  end
end
