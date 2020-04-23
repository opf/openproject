require 'spec_helper'

describe 'BCF snapshot column',
         type: :feature,
         js: true,
         with_config: { edition: 'bim' },
         with_mail: false do
  let(:project) { FactoryBot.create(:project, enabled_module_names: %w[bim work_package_tracking]) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:permissions) { %i[add_work_packages view_work_packages view_linked_issues] }
  let!(:work_package) { FactoryBot.create(:work_package, project: project) }
  let!(:bcf_issue) { FactoryBot.create(:bcf_issue_with_viewpoint, work_package: work_package) }
  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: permissions
  end
  let!(:query) do
    query              = FactoryBot.build(:query, user: user, project: project)
    query.column_names = ['subject', 'bcf_thumbnail']
    query.filters.clear
    query.show_hierarchies = false

    query.save!
    query
  end

  before do
    login_as(user)
  end

  it 'shows BCF snapshot column correctly (Regression)' do
    wp_table.visit_query query
    wp_table.expect_work_package_listed(work_package)

    page.within(".wp-row-#{work_package.id} td.bcfThumbnail") do
      image_path = "/api/bcf/2.1/projects/#{project.identifier}/topics/#{bcf_issue.uuid}/viewpoints/#{bcf_issue.viewpoints.first.uuid}/snapshot"
      expect(page).to have_selector("img[src=\"#{image_path}\"]")
    end
  end
end
