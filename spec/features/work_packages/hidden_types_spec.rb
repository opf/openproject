require 'spec_helper'

RSpec.describe 'Work package with hidden type', js: true do
  let(:user) { FactoryGirl.create :admin }
  let(:type) { FactoryGirl.create :type, attribute_visibility: attribute_visibility }

  let(:attribute_visibility) do
    {
      'status' => 'hidden'
    }
  end

  let(:project) { FactoryGirl.create(:project, types: [type]) }
  let(:work_package) {
    FactoryGirl.create(:work_package,
                       project: project,
                       type:    type,
                       status:  FactoryGirl.build(:status),
                       subject: 'Foobar')
  }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let!(:query) do
    query              = FactoryGirl.build(:query, user: user, project: project)
    query.column_names = ['subject', 'status']

    query.save!
    query
  end

  before do
    work_package
    login_as(user)

    wp_table.visit_query(query)
    wp_table.expect_work_package_listed(work_package)
  end

  it 'hides the subject field on table and single view' do
      status_field = wp_table.edit_field(work_package, :status)
      status_field.expect_text('-')
      expect(status_field).not_to be_editable

      # Visit details
      split_view = wp_table.open_split_view(work_package)
      split_view.view_all_attributes
      split_view.expect_hidden_field(:status)
  end
end
