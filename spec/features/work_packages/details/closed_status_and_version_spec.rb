require 'spec_helper'

describe 'Closed status and version in full view', js: true do
  let(:type) { FactoryBot.create(:type) }
  let(:status) { FactoryBot.create(:closed_status) }

  let(:project) { FactoryBot.create(:project, types: [type]) }

  let(:version) { FactoryBot.create :version, status: 'closed', project: project }
  let(:work_package) { FactoryBot.create :work_package, project: project, status: status, version: version }
  let(:wp_page) { ::Pages::FullWorkPackage.new(work_package, project) }

  let(:user) { FactoryBot.create :admin }

  before do
    login_as(user)
    wp_page.visit!
  end

  it 'shows a warning when trying to edit status' do
    # Should be initially editable (due to non specific schema)
    status = page.find('.wp-status-button button:not([disabled])')
    status.click

    wp_page.expect_and_dismiss_notification type: :error,
                                            message: I18n.t('js.work_packages.message_work_package_status_blocked')

    expect(page).to have_selector('.wp-status-button button[disabled]')
  end
end
