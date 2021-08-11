require 'spec_helper'

require 'features/work_packages/work_packages_page'
require 'support/edit_fields/edit_field'

describe 'Activity tab notifications', js: true, selenium: true do
  shared_let(:project) { FactoryBot.create :project_with_types, public: true }
  shared_let(:work_package) do
    work_package = FactoryBot.create(:work_package,
                                     project: project,
                                     created_at: 5.days.ago.to_date.to_s(:db))

    work_package.update({
      journal_notes: 'First comment on this wp.', 
      updated_at: 5.days.ago.to_date.to_s
    })
    work_package.update({
      journal_notes: 'Second comment on this wp.', 
      updated_at: 4.days.ago.to_date.to_s
    })
    work_package.update({
      journal_notes: 'Third comment on this wp.', 
      updated_at: 3.days.ago.to_date.to_s
    })

    work_package
  end
  shared_let(:admin) { FactoryBot.create(:admin) }
  shared_let(:full_view) { Pages::FullWorkPackage.new(work_package, project) }

  before do
    login_as(admin)
    full_view.visit!
  end

  context 'has notifications for the work package' do
    shared_let(:notification) do
      FactoryBot.create :notification,
                        recipient: admin,
                        project: project,
                        resource: work_package,
                        journal: work_package.journals.last
    end

    it 'Shows a notification bubble with the right number' do
      expect(page).to have_selector('[data-qa-selector="tab-counter-Activity"]', text: '1')
    end

    it 'Shows a notification icon next to activities that have an unread notification' do
      expect(page).to have_selector('[data-qa-selector="user-activity-bubble"]', count: 1)
      expect(page).to have_selector('[data-qa-activity-number="3"] [data-qa-selector="user-activity-bubble"]')
    end
  end

  context 'does not have notifications for the work package' do
    it 'Shows no notification bubble' do
      expect(page).not_to have_selector('[data-qa-selector="tab-counter-Activity"]')
    end

    it 'Does not show any notification icons next to activities' do
      expect(page).not_to have_selector('[data-qa-selector="user-activity-bubble"]')
    end
  end
end
