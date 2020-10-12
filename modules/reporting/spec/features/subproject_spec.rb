require 'spec_helper'

describe 'Cost report in subproject', type: :feature, js: true do
  let!(:project) { FactoryBot.create :project }
  let!(:subproject) { FactoryBot.create :project, parent: project }

  let!(:role) { FactoryBot.create :role, permissions: %i(view_cost_entries view_own_cost_entries) }
  let!(:user) do
    FactoryBot.create :user,
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