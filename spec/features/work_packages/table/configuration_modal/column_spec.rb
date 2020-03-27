require 'spec_helper'

describe 'Work Package table configuration modal columns spec', js: true do
  let(:user) { FactoryBot.create :admin }

  let(:project) { FactoryBot.create(:project) }
  let!(:wp_1) { FactoryBot.create(:work_package, project: project) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:columns) { ::Components::WorkPackages::Columns.new }
  let!(:work_package) { FactoryBot.create :work_package, project: project }

  let!(:query) do
    query = FactoryBot.build(:query, user: user, project: project)
    query.column_names = %w[id subject]

    query.save!
    query
  end

  before do
    login_as(user)
    wp_table.visit_query query
    wp_table.expect_work_package_listed work_package
    expect(page).to have_selector('.wp-table--table-header', text: 'ID')
    expect(page).to have_selector('.wp-table--table-header', text: 'SUBJECT')
  end

  shared_examples 'add and remove columns' do
    it do
      columns.open_modal
      columns.expect_checked 'ID'
      columns.expect_checked 'Subject'

      columns.remove 'Subject', save_changes: false
      columns.add 'Project', save_changes: true
      columns.expect_column_available 'Subject'
      columns.expect_column_not_available 'Project'

      expect(page).to have_selector('.wp-table--table-header', text: 'ID')
      expect(page).to have_selector('.wp-table--table-header', text: 'PROJECT')
      expect(page).to have_no_selector('.wp-table--table-header', text: 'SUBJECT')
    end
  end

  context 'When seeing the table' do
    it_behaves_like 'add and remove columns'


    context 'with three columns', driver: :firefox_headless_de do
      let!(:query) do
        query = FactoryBot.build(:query, user: user, project: project)
        query.column_names = %w[id project subject]

        query.save!
        query
      end

      it 'can reorder columns' do
        columns.open_modal
        columns.expect_checked 'ID'
        columns.expect_checked 'Project'
        columns.expect_checked 'Subject'

        # Drag subject left of project
        subject_column = columns.column_item('Subject').find('span')
        project_column = columns.column_item('Project').find('span')

        page
          .driver
          .browser
          .action
          .drag_and_drop(subject_column.native, project_column.native)
          .release
          .perform

        sleep 1

        columns.apply
        expect(page).to have_selector('.wp-table--table-header', text: 'ID')
        expect(page).to have_selector('.wp-table--table-header', text: 'PROJECT')
        expect(page).to have_selector('.wp-table--table-header', text: 'SUBJECT')

        names = all('.wp-table--table-header').map(&:text)
        # Depending on what browser is used, subject column may be first or second
        # it doesn't matter for the outcome of this test
        expect(names).to eq(%w[SUBJECT ID PROJECT]).or(eq(%w[ID SUBJECT PROJECT]))
      end
    end
  end
end
