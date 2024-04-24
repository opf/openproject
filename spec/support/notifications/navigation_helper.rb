class Notifications::NavigationHelper
  attr_reader :center,
              :notification,
              :work_package

  def initialize(center, notification, work_package)
    @center = center
    @notification = notification
    @work_package = work_package
  end

  def open_and_close_the_center
    # Open the notification center and close it directly
    center.open
    center.expect_work_package_item notification

    center.close
  end

  def open_center_and_navigate_within
    # Open the notification center and close it directly
    center.open
    center.show_all
    center.expect_work_package_item notification

    # Open a notification
    center.click_item notification
    split_screen = ::Pages::SplitWorkPackage.new work_package
    split_screen.expect_tab :activity
    split_screen.switch_to_tab tab: "relations"

    center.close
  end

  def open_center_and_navigate_out
    # Open the notification center and close it directly
    center.open
    center.show_all
    center.expect_work_package_item notification

    # Open a notification
    center.click_item notification
    split_screen = ::Pages::SplitWorkPackage.new work_package
    split_screen.expect_tab :activity

    # Switch to WP full view and back
    wp_full = split_screen.switch_to_fullscreen
    wp_full.expect_tab :activity

    wp_full.go_back
    split_screen.expect_open

    center.close
  end
end
