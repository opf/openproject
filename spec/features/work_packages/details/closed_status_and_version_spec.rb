require 'spec_helper'

describe 'Closed status and version in full view', js: true do
  let(:type) { create(:type) }
  let(:status) { create(:closed_status) }

  let(:project) { create(:project, types: [type]) }

  let(:version) { create :version, status: 'closed', project: project }
  let(:work_package) { create :work_package, project: project, status: status, version: version }
  let(:wp_page) { ::Pages::FullWorkPackage.new(work_package, project) }

  let(:user) { create :admin }

  before do
    login_as(user)
    wp_page.visit!
  end

  it 'shows a warning when trying to edit status' do
    # Should be initially editable (due to non specific schema)
    status = page.find('[data-qa-selector="op-wp-status-button"] button:not([disabled])')
    status.click

    wp_page.expect_and_dismiss_toaster type: :error,
                                            message: I18n.t('js.work_packages.message_work_package_status_blocked')

    expect(page).to have_selector('[data-qa-selector="op-wp-status-button"] button[disabled]')
  end
end
