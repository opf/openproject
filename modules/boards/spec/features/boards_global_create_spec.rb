# frozen_string_literal: true

require 'spec_helper'
require_relative 'support/board_global_create_page'

RSpec.describe 'Boards',
               'Creating a view from a Global Context',
               :js,
               :with_cuprite,
               with_ee: %i[board_view] do
  shared_let(:project) { create(:project, enabled_module_names: %i[work_package_tracking board_view]) }
  shared_let(:admin) { create(:admin) }

  shared_let(:status) { create(:default_status) }

  shared_let(:new_board_page) { Pages::NewBoard.new }

  before do
    login_as admin
  end

  context 'within the global index page' do
    before do
      visit boards_all_path
    end

    context 'when clicking on the create button' do
      before do
        new_board_page.navigate_by_create_button
      end

      it 'navigates to the global create form' do
        expect(page).to have_current_path new_work_package_board_path
        expect(page).to have_content I18n.t('boards.label_create_new_board')
      end
    end
  end

  context 'within the global create page' do
    before do
      new_board_page.visit!
    end

    context 'with all fields set' do
      before do
        wait_for_reload # Halt until the project autocompleter is ready

        new_board_page.set_title "Gotham Renewal Board"
        new_board_page.set_project project
      end

      context 'when creating a "Basic" board' do
        before do
          new_board_page.set_board_type 'Basic'
          new_board_page.click_on_submit

          wait_for_reload
        end

        it 'creates the board and redirects me to it' do
          expect(page).to have_text(I18n.t(:notice_successful_create))
          expect(page).to have_current_path("/projects/#{project.identifier}/boards/#{Boards::Grid.last.id}")
          expect(page).to have_text "Gotham Renewal Board"
        end
      end

      context 'when creating a "Status" board' do
        before do
          new_board_page.set_board_type 'Status'
          new_board_page.click_on_submit

          wait_for_reload
        end

        it 'creates the board and redirects me to it' do
          expect(page).to have_text(I18n.t(:notice_successful_create))
          expect(page).to have_current_path("/projects/#{project.identifier}/boards/#{Boards::Grid.last.id}")
          expect(page).to have_text "Gotham Renewal Board"
          expect(page).to have_selector("[data-query-name='#{status.name}']")
        end
      end
    end
  end
end
