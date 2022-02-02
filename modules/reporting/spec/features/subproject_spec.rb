require 'spec_helper'

describe 'Cost report in subproject', type: :feature, js: true do
  let!(:project) { create :project }
  let!(:subproject) { create :project, parent: project }

  let!(:role) { create :role, permissions: %i(view_cost_entries view_own_cost_entries) }
  let!(:user) do
    create :user,
                      member_in_project: subproject,
                      member_through_role: role
  end

  before do
    login_as(user)
    visit project_path(subproject)
  end

  it 'provides filtering' do
    within '#main-menu' do
      click_on 'Time and costs'
    end

    within '#content' do
      expect(page).to have_content 'New cost report'
    end
  end
end
