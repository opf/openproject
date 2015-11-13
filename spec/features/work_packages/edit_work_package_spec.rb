require 'spec_helper'
require 'features/work_packages/details/inplace_editor/work_package_field'
require 'features/work_packages/work_packages_page'
require 'features/page_objects/notification'


describe 'edit work package', js: true do
  let(:user) { FactoryGirl.create :admin }
  let(:project) { FactoryGirl.create(:project) }
  let(:work_package) { FactoryGirl.create(:work_package, project: project) }
  let(:work_packages_page) { WorkPackagesPage.new(project) }

  let(:new_subject) { 'Some other subject' }
  let(:subject_field) { WorkPackageField.new(page, :subject) }

  before do
    login_as(user)

    visit edit_work_package_path(work_package)
  end

  it 'shows the work package in edit mode' do
    subject = page.find("#inplace-edit--write-value--subject")
    expect(subject.value).to eq(work_package.subject)

    subject.set new_subject
    find('#work-packages--edit-actions-save').click

    subject_field.expect_state_text(subject)
  end
end
