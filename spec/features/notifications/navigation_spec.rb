require 'spec_helper'
require 'support/components/notifications/center'

describe "Notification center navigation", type: :feature, js: true do
  shared_let(:project) { FactoryBot.create :project }
  shared_let(:work_package) { FactoryBot.create :work_package, project: project }
  shared_let(:second_work_package) { FactoryBot.create :work_package, project: project }
  shared_let(:recipient) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: %i[view_work_packages]
  end
  shared_let(:notification) do
    FactoryBot.create :notification,
                      recipient: recipient,
                      project: project,
                      resource: work_package,
                      journal: work_package.journals.last
  end

  shared_let(:second_notification) do
    FactoryBot.create :notification,
                      recipient: recipient,
                      project: project,
                      resource: second_work_package,
                      journal: second_work_package.journals.last
  end

  let(:center) { ::Components::Notifications::Center.new }
  let(:activity_tab) { ::Components::WorkPackages::Activities.new(work_package) }
  let(:split_screen) { ::Pages::SplitWorkPackage.new work_package }

  describe 'the back button brings me back to where I came from' do
    current_user { recipient }
    let(:navigation_helper) { ::Notifications::NavigationHelper.new(center, notification, work_package) }

    it 'when coming from a rails based page' do
      visit home_path

      navigation_helper.open_and_close_the_center
      expect(page).to have_current_path home_path

      navigation_helper.open_center_and_navigate_within
      expect(page).to have_current_path home_path

      navigation_helper.open_center_and_navigate_out
      expect(page).to have_current_path home_path
    end

    it 'when coming from an angular page' do
      visit project_work_package_path(project, work_package, state: 'activity')

      navigation_helper.open_and_close_the_center
      expect(page).to have_current_path project_work_package_path(project, work_package, state: 'activity')

      navigation_helper.open_center_and_navigate_within
      expect(page).to have_current_path project_work_package_path(project, work_package, state: 'activity')

      navigation_helper.open_center_and_navigate_out
      expect(page).to have_current_path project_work_package_path(project, work_package, state: 'activity')
    end
  end

  describe 'the path updates accordingly' do
    current_user { recipient }

    it 'when navigating between the tabs' do
      visit home_path
      center.open
      center.expect_bell_count 2
      expect(page).to have_current_path "/notifications"

      # Details view of WP opens with activity tab
      center.click_item notification
      split_screen.expect_open
      expect(page).to have_current_path "/notifications/details/#{work_package.id}/activity"

      # Switch to the relations tab
      split_screen.switch_to_tab tab: 'relations'
      expect(page).to have_current_path "/notifications/details/#{work_package.id}/relations"

      # Navigate to full view and back
      wp_full = split_screen.switch_to_fullscreen
      expect(page).to have_current_path "/work_packages/#{work_package.id}/relations"

      wp_full.go_back
      expect(page).to have_current_path "/notifications/details/#{work_package.id}/relations"

      # Close the split screen
      split_screen.close
      expect(page).to have_current_path "/notifications"
    end
  end
end
