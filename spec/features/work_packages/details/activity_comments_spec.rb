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

    ng_wait
  end

  it 'should alert user if navigating with unsaved form' do
    fill_in I18n.t('js.label_add_comment_title'), with: 'Foobar'

    visit root_path

    page.driver.browser.switch_to.alert.accept

    expect(current_path).to eq(root_path)
  end

  it 'should not alert if comment has been submitted' do
    fill_in I18n.t('js.label_add_comment_title'), with: 'Foobar'

    click_button I18n.t('js.label_add_comment')

    visit root_path

    expect(current_path).to eq(root_path)
  end
end
