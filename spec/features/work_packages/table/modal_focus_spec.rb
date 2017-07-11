require 'spec_helper'

describe 'Modal focus in work package table', js: true do
  let(:user) { FactoryGirl.create :admin }

  let!(:project) { FactoryGirl.create(:project) }
  let!(:work_package) { FactoryGirl.create(:work_package, project: project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let!(:query) do
    query = FactoryGirl.build(:query, user: user, project: project)
    query.show_hierarchies = false
    query.save!
    query
  end

  before do
    login_as user

    wp_table.visit_query query
    loading_indicator_saveguard
    find('#work-packages-settings-button').click
  end

  describe 'columns' do
    it 'sets the focus in the column selection' do
      within '#settingsDropdown' do
        click_link 'Columns'
      end

      loading_indicator_saveguard
      expect(page).to have_selector('.ng-modal-window h3', text: 'Columns')
      expect(page).to have_focus_on('#selected_columns .select2-input')
    end
  end

  describe 'sorting' do
    it 'sets the focus in the sort selection' do
      within '#settingsDropdown' do
        click_link 'Sort by'
      end

      loading_indicator_saveguard
      expect(page).to have_selector('.ng-modal-window h3', text: 'Sorting')
      expect(page).to have_focus_on('#modal-sorting-attribute-0')
    end
  end

  describe 'group by' do
    it 'sets the focus in the sort selection' do
      within '#settingsDropdown' do
        click_link 'Group by'
      end

      loading_indicator_saveguard
      expect(page).to have_selector('.ng-modal-window h3', text: 'Group by')
      expect(page).to have_focus_on('#selected_columns_new')
    end
  end
end
