require 'spec_helper'

describe 'filter by watcher', js: true do
  let(:user) { FactoryGirl.create :admin }
  let(:watcher) { FactoryGirl.create :user }
  let(:project) { FactoryGirl.create :project }
  let(:role) { FactoryGirl.create :existing_role, permissions: [:view_work_packages] }

  let(:work_packages) { FactoryGirl.create_list :work_package, 10, project: project }
  let(:watched_wps) { [work_packages[3], work_packages[5], work_packages[7]] }

  let(:wp_table) { ::Pages::WorkPackagesTable.new }
  let(:filters) { ::Components::WorkPackages::Filters.new }

  before do
    project.add_member! watcher, role

    watched_wps.each_with_index do |wp, i|
      wp.add_watcher watcher
      wp.subject = "Watched WP ##{i}"
      wp.save!
    end

    login_as(user)
    wp_table.visit!
  end

  # Regression test for bug #24114 (broken watcher filter)
  it 'should only filter work packages by watcher' do
    filters.open
    loading_indicator_saveguard

    filters.filter_by_watcher watcher.name
    loading_indicator_saveguard

    expect(wp_table).to have_work_packages_listed watched_wps
    expect(wp_table).not_to have_work_packages_listed (work_packages - watched_wps)
  end
end
