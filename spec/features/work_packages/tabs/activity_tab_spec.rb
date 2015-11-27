require 'spec_helper'

require 'features/work_packages/work_packages_page'

describe 'Activity tab', js: true, selenium: true do
  let(:project) { FactoryGirl.create :project_with_types, is_public: true }
  let!(:work_package) {
    FactoryGirl.create(:work_package,
                       project: project,
                       created_at: '2015-11-20 12:00 +0100',
                       subject: initial_subject,
                       journal_notes: initial_comment)
  }

  let(:initial_subject) { 'My Subject' }
  let(:initial_comment) { 'First comment on this wp.' }
  let(:comments_in_reverse) { false }

  let!(:note_1) {
    FactoryGirl.create :work_package_journal,
                       journable_id: work_package.id,
                       created_at: 3.days.ago.to_date.to_s(:db),
                       notes: 'Updated the subject and description',
                       version: 2,
                       user: user,
                       data: FactoryGirl.build(:journal_work_package_journal,
                                               subject: 'New subject',
                                               description: 'Some not so long description.')
  }

  let!(:note_2) {
    FactoryGirl.create :work_package_journal,
                       journable_id: work_package.id,
                       created_at: 1.days.ago.to_date.to_s(:db),
                       version: 3,
                       notes: 'Another comment by a different user',
                       user: FactoryGirl.create(:admin)
  }

  before do
    login_as(user)
    allow(user.pref).to receive(:warn_on_leaving_unsaved?).and_return(false)
    allow(user.pref).to receive(:comments_in_reverse_order?).and_return(comments_in_reverse)
  end

  shared_examples 'shows activities in order' do
    let(:journals) {
      journals = [note_1, note_2]
      journals.reverse! if comments_in_reverse

      journals
    }

    it 'shows activities in ascending order' do
      expect(page).to have_selector('.user-comment > .message', count: 3)
      expect(page).to have_selector('.activity-date', text: 'November 25, 2015')
      expect(page).to have_selector('.activity-date', text: 'November 26, 2015')

      journals.each_with_index do |journal, idx|
        activity = page.find("#activity-#{idx + 1}")
        expect(activity).to have_selector('.user', text: journal.user.name)
        expect(activity).to have_selector('.user-comment > .message', text: journal.notes)

        if activity == note_1
          expect(activity).to have_selector('.work-package-details-activities-messages .message',
                                            count: 2)
          expect(activity).to have_selector('.message',
                                            text: "Subject changed from #{initial_subject} " \
                                                  "to #{journal.data.subject}")
        end
      end
    end
  end

  shared_examples 'activity tab' do
    before do
      work_package_page.visit_tab! 'activity'
      expect(page).to have_selector('.user-comment > .message',
                                    text: initial_comment)
    end

    context 'with permission' do
      let(:user) { FactoryGirl.create(:admin) }
      context 'with ascending comments' do
        let(:comments_in_reverse) { false }
        it_behaves_like 'shows activities in order'
      end

      context 'with reversed comments' do
        let(:comments_in_reverse) { true }
        it_behaves_like 'shows activities in order'
      end

      it 'can quote a previous comment' do
        # Hover comment
        page.find('#activity-1 .work-package-details-activities-activity-contents').hover

        # Quote this comment
        page.find('.comments-icons .icon-quote', visible: false).click
        expect(field.editing?).to be true

        # Add our comment
        quote = field.input_element[:value]
        expect(quote).to include("> #{initial_comment}")
        quote << "\nthis is some remark under a quote"
        field.input_element.set(quote)
        field.submit_by_click

        expect(page).to have_selector('.user-comment > .message', count: 4)
        expect(page).to have_selector('.user-comment > .message blockquote')
      end
    end


    context 'with no permission' do
      let(:user) { FactoryGirl.create(:user) }

      it 'shows the activities, but does not allow commenting' do
        expect(body).not_to have_selector('.work-packages--activity--add-comment')
      end
    end
  end

  context 'split screen' do
    let(:work_package_page) { Pages::SplitWorkPackage.new(work_package, project) }
    it_behaves_like 'activity tab'
  end

  context 'full screen' do
    let(:work_package_page) { Pages::FullWorkPackage.new(work_package) }
    it_behaves_like 'activity tab'
  end
end
