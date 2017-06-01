require 'spec_helper'
require 'features/page_objects/notification'

describe 'Work package transitive status workflows', js: true do
  let(:dev_role) do
    FactoryGirl.create :role,
                       permissions: [:view_work_packages,
                                     :edit_work_packages]
  end
  let(:dev) do
    FactoryGirl.create :user,
                       firstname: 'Dev',
                       lastname: 'Guy',
                       member_in_project: project,
                       member_through_role: dev_role
  end

  let(:type) { FactoryGirl.create :type }
  let(:project) { FactoryGirl.create(:project, types: [type]) }

  let(:work_package) {
    work_package = FactoryGirl.create :work_package,
                                      project: project,
                                      type: type,
                                      created_at: 5.days.ago.to_date.to_s(:db)

    note_journal = work_package.journals.last
    note_journal.update_attributes(created_at: 5.days.ago.to_date.to_s)

    work_package
  }
  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }

  let(:status_from) { work_package.status }
  let(:status_intermediate) { FactoryGirl.create :status }
  let(:status_to) { FactoryGirl.create :status }

  let(:workflows) {
    FactoryGirl.create :workflow,
                       type_id: type.id,
                       old_status: status_from,
                       new_status: status_intermediate,
                       role: dev_role

    FactoryGirl.create :workflow,
                       type_id: type.id,
                       old_status: status_intermediate,
                       new_status: status_to,
                       role: dev_role
  }

  before do
    login_as(dev)

    work_package
    workflows

    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  ##
  # Regression test for #24129
  it 'allows to move to the final status as defined in the workflow' do
    wp_page.update_attributes status: status_intermediate.name
    wp_page.expect_attributes status: status_intermediate.name

    wp_page.expect_activity_message "Status changed from #{status_from.name} to " \
                                    "#{status_intermediate.name}"

    wp_page.update_attributes status: status_to.name
    wp_page.expect_attributes status: status_to.name

    wp_page.expect_activity_message "Status changed from #{status_from.name} to " \
                                    "#{status_to.name}"

    work_package.reload
    expect(work_package.status).to eq(status_to)

  end
end
