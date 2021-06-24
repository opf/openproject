require 'spec_helper'
require 'support/components/notifications/center'

describe "Notification bell", type: :feature, js: true do
  shared_let(:project) { FactoryBot.create :project }
  shared_let(:work_package) { FactoryBot.create :work_package, project: project }
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

  let(:center) { ::Components::Notifications::Center.new }

  describe 'basic use case' do
    current_user { recipient }

    it 'can see the notification and dismiss it' do
      visit home_path
      center.expect_bell_count 1
      center.open

      center.expect_work_package_item notification
      center.mark_all_read
      center.expect_closed

      center.expect_bell_count 0
      notification.reload
      expect(notification.read_ian).to be_truthy
    end
  end
end
