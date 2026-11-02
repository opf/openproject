# frozen_string_literal: true

module TestManagement
  # Server-rendered content of the work package "Testing" tab (full view and
  # split view). The Angular tab shell loads it into a <turbo-frame>; see
  # frontend/module/testing-tab.
  class WorkPackageTestingTabController < ApplicationController
    helper TestManagement::TestCasesHelper
    helper TestManagement::TestRunsHelper
    helper TestManagement::MilestonesHelper

    before_action :find_work_package
    before_action :authorize_testing_tab
    authorization_checked! :index, :count

    # Shared by the controller, the split view menu entry and the API link:
    # module enabled in the work package's project and :show_testing_content
    # granted there (OpenProject drops permissions of disabled modules).
    def self.tab_visible?(user, work_package)
      return false if work_package.nil? || work_package.new_record?
      return false unless work_package.project&.module_enabled?(:test_management)

      user.allowed_in_work_package?(:show_testing_content, work_package)
    end

    def index
      @testing = TestManagement::WorkPackageTesting.new(@work_package, user: current_user)
      # Milestones | Runs | Cases switcher (links inside the Turbo frame).
      @view = @testing.view_for(params[:view])
      render layout: false
    end

    def count
      render json: { count: TestManagement::WorkPackageTesting.count_for(@work_package, user: current_user) }
    end

    private

    def find_work_package
      @work_package = WorkPackage.visible(current_user).find(params.expect(:work_package_id))
      @project = @work_package.project
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def authorize_testing_tab
      return if self.class.tab_visible?(current_user, @work_package)

      deny_access(not_found: true)
    end
  end
end
