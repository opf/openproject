require 'spec_helper'

require 'features/work_packages/work_packages_page'
require 'support/work_packages/work_package_field'

describe 'Activity tab', js: true, selenium: true do
  def alter_work_package_at(work_package, attributes:, at:, user: User.current)
    work_package.update_attributes(attributes.merge({ updated_at: at }))

    note_journal = work_package.journals.last
    note_journal.update_attributes(created_at: at, user: attributes[:user])
  end

  let(:project) { FactoryGirl.create :project_with_types, is_public: true }
  let!(:work_package) {
    work_package = FactoryGirl.create(:work_package,
                                      project: project,
                                      created_at: 5.days.ago.to_date.to_s(:db),
                                      subject: initial_subject,
                                      journal_notes: initial_comment)

    note_journal = work_package.journals.last
    note_journal.update_attributes(created_at: 5.days.ago.to_date.to_s)

    work_package
  }

  let(:initial_subject) { 'My Subject' }
  let(:initial_comment) { 'First comment on this wp.' }
  let(:comments_in_reverse) { false }

  let(:initial_note) {
    work_package.journals[0]
  }

  let!(:note_1) {
    attributes = { subject: 'New subject',
                   description: 'Some not so long description.',
                   journal_notes: 'Updated the subject and description' }

    alter_work_package_at(work_package,
                          attributes: attributes,
                          at: 3.days.ago.to_date.to_s(:db),
                          user: user)

    work_package.journals.last
  }

  let!(:note_2) {
    attributes = { journal_notes: 'Another comment by a different user' }

    alter_work_package_at(work_package,
                          attributes: attributes,
                          at: 1.days.ago.to_date.to_s(:db),
                          user: FactoryGirl.create(:admin))

    work_package.journals.last
  }

  before do
    login_as(user)
    allow(user.pref).to receive(:warn_on_leaving_unsaved?).and_return(false)
    allow(user.pref).to receive(:comments_in_reverse_order?).and_return(comments_in_reverse)
  end

  shared_examples 'shows activities in order' do
    let(:journals) {
      journals = [initial_note, note_1, note_2]

      journals
    }

    it 'shows activities in ascending order' do
      journals.each_with_index do |journal, idx|
        date_selector = ".work-package-details-activities-activity:nth-of-type(#{idx + 1}) " +
                        '.activity-date'
        # Do not use :long format to match the printed date without double spaces
        # on the first 9 days of the month
        expect(page).to have_selector(date_selector,
                                      text: journal.created_at.to_date.strftime("%B %-d, %Y"))

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
      let(:role) {
        FactoryGirl.create(:role, permissions: [:view_work_packages,
                                                :add_work_package_notes])
      }
      let(:user) {
        FactoryGirl.create(:user,
                           member_in_project: project,
                           member_through_role: role)
      }

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
        page.find('#activity-1 .comments-icons .icon-quote', visible: false).click

        field = WorkPackageField.new(page, 'activity', '.work-packages--activity--add-comment')

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
      let(:role) {
        FactoryGirl.create(:role, permissions: [:view_work_packages])
      }
      let(:user) {
        FactoryGirl.create(:user,
                           member_in_project: project,
                           member_through_role: role)
      }

      it 'shows the activities, but does not allow commenting' do
        expect(page).not_to have_selector('.work-packages--activity--add-comment', visible: true)
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
