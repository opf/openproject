require "spec_helper"

RSpec.describe "BCF snapshot column", :js,
               with_config: { edition: "bim" } do
  let(:project) { create(:project, enabled_module_names: %w[bim work_package_tracking]) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:permissions) { %i[add_work_packages view_work_packages view_linked_issues] }
  let!(:work_package) { create(:work_package, project:) }
  let!(:bcf_issue) { create(:bcf_issue_with_viewpoint, work_package:) }
  let(:user) do
    create(:user,
           member_with_permissions: { project => permissions })
  end
  let!(:query) do
    query              = build(:query, user:, project:)
    query.column_names = ["subject", "bcf_thumbnail"]
    query.filters.clear
    query.show_hierarchies = false

    query.save!
    query
  end

  before do
    login_as(user)
  end

  it "shows BCF snapshot column correctly (Regression)" do
    wp_table.visit_query query
    wp_table.expect_work_package_listed(work_package)

    page.within(".wp-row-#{work_package.id} td.bcfThumbnail") do
      image_path = "/api/bcf/2.1/projects/#{project.identifier}/topics/#{bcf_issue.uuid}/viewpoints/#{bcf_issue.viewpoints.first.uuid}/snapshot"
      expect(page).to have_css("img[src=\"#{image_path}\"]")
    end
  end
end
