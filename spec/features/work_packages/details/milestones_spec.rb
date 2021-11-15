require 'spec_helper'

describe 'Milestones full screen v iew', js: true do
  let(:type) { FactoryBot.create :type, is_milestone: true }
  let(:project) { FactoryBot.create(:project, types: [type]) }
  let!(:work_package) do
    FactoryBot.create(:work_package,
                      project: project,
                      type: type,
                      subject: 'Foobar')
  end

  let(:wp_page) { ::Pages::FullWorkPackage.new(work_package, project) }
  let(:button) { find('.add-work-package', wait: 5) }

  before do
    login_as(user)
    wp_page.visit!
  end

  context 'user has :add_work_packages permission' do
    let(:user) do
      FactoryBot.create(:user, member_in_project: project, member_through_role: role)
    end
    let(:role) { FactoryBot.create(:role, permissions: permissions) }
    let(:permissions) do
      %i[view_work_packages add_work_packages]
    end

    it 'shows the button as enabled' do
      expect(button).not_to be_disabled

      button.click
      expect(page).to have_selector('.menu-item', text: type.name.upcase)
    end
  end

  context 'user has :view_work_packages permission only' do
    let(:user) do
      FactoryBot.create(:user, member_in_project: project, member_through_role: role)
    end
    let(:role) { FactoryBot.create(:role, permissions: permissions) }
    let(:permissions) do
      %i[view_work_packages]
    end

    it 'shows the button as correctly disabled' do
      expect(button['disabled']).to be_truthy
    end
  end
end
