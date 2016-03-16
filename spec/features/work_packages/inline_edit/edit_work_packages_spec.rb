require 'spec_helper'

describe 'Inline editing work packages', js: true do
  let(:dev_role) do
    FactoryGirl.create :role,
                       permissions: [:view_work_packages,
                                     :add_work_packages]
  end
  let(:dev) do
    FactoryGirl.create :user,
                       firstname: 'Dev',
                       lastname: 'Guy',
                       member_in_project: project,
                       member_through_role: dev_role
  end
  let(:manager_role) do
    FactoryGirl.create :role,
                       permissions: [:view_work_packages,
                                     :edit_work_packages]
  end
  let(:manager) do
    FactoryGirl.create :user,
                       firstname: 'Manager',
                       lastname: 'Guy',
                       member_in_project: project,
                       member_through_role: manager_role
  end
  let(:type) { FactoryGirl.create :type }
  let(:type2) { FactoryGirl.create :type }
  let(:project) { FactoryGirl.create(:project, types: [type, type2]) }
  let(:work_package) {
    FactoryGirl.create(:work_package,
                       author: dev,
                       project: project,
                       type: type,
                       subject: 'Foobar')
  }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:fields) { InlineEditField.new(wp_table, work_package) }

  let(:priority2) { FactoryGirl.create :priority }
  let(:status2) { FactoryGirl.create :status }
  let(:workflow) do
    FactoryGirl.create :workflow,
                       type_id: type2.id,
                       old_status: work_package.status,
                       new_status: status2,
                       role: manager_role
  end
  let(:version) { FactoryGirl.create :version, project: project }
  let(:category) { FactoryGirl.create :category, project: project }

  before do
    login_as(manager)

    manager
    dev
    priority2
    workflow

    wp_table.visit!
    wp_table.expect_work_package_listed(work_package)
  end

  it 'allows updating and seeing the results' do
    subject_field = wp_table.edit_field(work_package, :subject)
    subject_field.expect_text('Foobar')

    subject_field.activate!

    subject_field.set_value('New subject!')

    expect(UpdateWorkPackageService).to receive(:new).and_call_original
    subject_field.save!
    subject_field.expect_text('New subject!')

    work_package.reload
    expect(work_package.subject).to eq('New subject!')
  end

  it 'allows to subsequently edit multiple fields' do
    subject_field = wp_table.edit_field(work_package, :subject)
    priority_field = wp_table.edit_field(work_package, :priority)

    expect(UpdateWorkPackageService).to receive(:new).and_call_original
    subject_field.activate!
    subject_field.set_value('Other subject!')

    priority_field.activate!
    priority_field.set_value(priority2.name)
    priority_field.expect_inactive!

    subject_field.expect_text('Other subject!')
    priority_field.expect_text(priority2.name)

    work_package.reload
    expect(work_package.subject).to eq('Other subject!')
    expect(work_package.priority.id).to eq(priority2.id)
  end

  it 'provides error handling' do
    subject_field = wp_table.edit_field(work_package, :subject)
    subject_field.expect_text('Foobar')

    subject_field.activate!

    subject_field.set_value('')

    expect(UpdateWorkPackageService).to receive(:new).and_call_original
    subject_field.save!
    subject_field.expect_error

    work_package.reload
    expect(work_package.subject).to eq('Foobar')
  end
end
