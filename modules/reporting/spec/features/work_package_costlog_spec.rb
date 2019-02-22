require 'spec_helper'

describe 'Cost report showing my own times', type: :feature, js: true do
  let(:project) { FactoryBot.create :project }
  let(:user) do
    FactoryBot.create(:user, member_in_project: project, member_through_role: role)
  end
  let(:role) { FactoryBot.create(:role, permissions: permissions) }
  let(:permissions) { %i[view_work_packages view_own_cost_entries] }

  let(:budget) do
    FactoryBot.create(:cost_object, project: project)
  end
  let(:cost_type) { FactoryBot.create(:cost_type, name: 'Foobar', unit: 'Foobar', unit_plural: 'Foobars') }
  let(:work_package) { FactoryBot.create :work_package, project: project, cost_object: budget }
  let(:wp_page) { Pages::FullWorkPackage.new work_package, project }

  let(:cost_entry) do
    FactoryBot.build(:cost_entry,
                     cost_type: cost_type,
                     project: project,
                     work_package: work_package,
                     spent_on: Date.today,
                     units: '10',
                     user: user,
                     comments: 'foobar')
  end


  before do
    login_as user
    cost_entry.save!
    wp_page.visit!
  end

  it 'allows visiting the costs which redirects to cost reports' do
    new_window = window_opened_by do
      page.find('.costsByType a', text: '10 Foobar').click
    end

    within_window new_window do
      expect(page).to have_selector('#query_saved_name', text: 'New cost report')
      expect(page).to have_field('values[work_package_id][]', with: work_package.id)
      expect(page).to have_selector('td.units', text: '10.0 Foobars')
    end
  end
end
