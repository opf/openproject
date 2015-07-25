require 'spec_helper'

require 'features/work_packages/shared_contexts'

describe 'activity comments', js: true do
  let(:project) { FactoryGirl.create :project_with_types, is_public: true }
  let!(:work_package) { FactoryGirl.create(:work_package, project: project) }
  let(:user) { FactoryGirl.create :admin }

  include_context 'maximized window'

  before do
    allow(User).to receive(:current).and_return(user)
    visit project_work_packages_path(project)

    ensure_wp_table_loaded

    row = page.find("#work-package-#{work_package.id}")
    row.double_click

    expect(find('#add-comment-text')).to be_present
  end

  it 'should alert user if navigating with unsaved form' do
    page.execute_script("jQuery('#add-comment-text').val('Foobar').trigger('change')")
    visit root_path
    page.driver.browser.switch_to.alert.accept
    expect(current_path).to eq(root_path)
  end

  it 'should not alert if comment has been submitted' do
    page.execute_script("jQuery('#add-comment-text').val('Foobar').trigger('change')")
    page.execute_script("jQuery('#add-comment-text').siblings('button').trigger('click')")
    visit root_path
    expect(current_path).to eq(root_path)
  end
end
