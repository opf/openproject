require 'spec_helper'

require 'features/work_packages/work_packages_page'
require 'support/edit_fields/edit_field'

describe 'Activity tab', js: true, selenium: true do
  def alter_work_package_at(work_package, attributes:, at:, user: User.current)
    work_package.update(attributes.merge(updated_at: at))

    note_journal = work_package.journals.last
    note_journal.update(created_at: at, user: attributes[:user])
  end

  let(:project) { FactoryBot.create :project_with_types, public: true }
  let!(:work_package) do
    work_package = FactoryBot.create(:work_package,
                                     project: project,
                                     created_at: 5.days.ago.to_date.to_s(:db),
                                     subject: initial_subject,
                                     journal_notes: initial_comment)

    note_journal = work_package.journals.last
    note_journal.update(created_at: 5.days.ago.to_date.to_s)

    work_package
  end

  let(:initial_subject) { 'My Subject' }
  let(:initial_comment) { 'First comment on this wp.' }
  let(:comments_in_reverse) { false }
  let(:activity_tab) { ::Components::WorkPackages::Activities.new(work_package) }

  let(:initial_note) do
    work_package.journals[0]
  end

  let!(:note_1) do
    attributes = { subject: 'New subject', description: 'Some not so long description.' }

    alter_work_package_at(work_package,
                          attributes: attributes,
                          at: 3.days.ago.to_date.to_s(:db),
                          user: user)

    work_package.journals.last
  end

  let!(:note_2) do
    attributes = { journal_notes: 'Another comment by a different user' }

    alter_work_package_at(work_package,
                          attributes: attributes,
                          at: 1.days.ago.to_date.to_s(:db),
                          user: FactoryBot.create(:admin))

    work_package.journals.last
  end

  let!(:revision) do
    repo = FactoryBot.build(:repository_subversion,
                            project: project)

    Setting.enabled_scm = Setting.enabled_scm << repo.vendor

    repo.save!

    changeset = FactoryBot.build(:changeset,
                                 comments: 'A comment on a changeset',
                                 committed_on: 2.days.ago.to_date.to_s(:db),
                                 repository: repo,
                                 committer: 'cool@person.org')

    work_package.changesets << changeset

    changeset
  end

  before do
    login_as(user)
    allow(user.pref).to receive(:warn_on_leaving_unsaved?).and_return(false)
    allow(user.pref).to receive(:comments_sorting).and_return(comments_in_reverse ? 'desc' : 'asc')
    allow(user.pref).to receive(:comments_in_reverse_order?).and_return(comments_in_reverse)
  end

  shared_examples 'shows activities in order' do
    it 'shows activities in ascending order' do
      activities.each_with_index do |activity, idx|
        actual_index =
          if comments_in_reverse
            activities.length - idx
          else
            idx + 1
          end

        date_selector = ".work-package-details-activities-activity:nth-of-type(#{actual_index}) " +
          '.activity-date'
        # Do not use :long format to match the printed date without double spaces
        # on the first 9 days of the month
        expected_date = if activity.is_a?(Journal)
          activity.created_at
        else
          activity.committed_on
        end.to_date.strftime("%B %-d, %Y")

        expect(page).to have_selector(date_selector,
                                      text: expected_date)

        activity = page.find("#activity-#{idx + 1}")

        if activity.is_a?(Journal) && activity.id != note_1.id
          expect(activity).to have_selector('.user', text: activity.user.name)
          expect(activity).to have_selector('.user-comment > .message', text: activity.notes, visible: :all)
        elsif activity.is_a?(Changeset)
          expect(activity).to have_selector('.user', text: User.find(activity.user_id).name)
          expect(activity).to have_selector('.user-comment > .message', text: activity.notes, visible: :all)
        elsif activity == note_1
          expect(activity).to have_selector('.work-package-details-activities-messages .message',
                                            count: 2)
          expect(activity).to have_selector('.message',
                                            text: "Subject changed from #{initial_subject} " \
                                                  "to #{activity.data.subject}")
        end
      end
    end
  end

  shared_examples 'activity tab' do
    before do
      work_package_page.visit_tab! 'activity'
      work_package_page.ensure_page_loaded
      expect(page).to have_selector('.user-comment > .message',
                                    text: initial_comment)
    end

    context 'with permission' do
      let(:role) do
        FactoryBot.create(:role, permissions: %i[view_work_packages
                                                 view_changesets
                                                 add_work_package_notes])
      end
      let(:user) do
        FactoryBot.create(:user,
                          member_in_project: project,
                          member_through_role: role)
      end
      let(:activities) do
        [initial_note, note_1, revision, note_2]
      end

      context 'with ascending comments' do
        let(:comments_in_reverse) { false }
        it_behaves_like 'shows activities in order'
      end

      context 'with reversed comments' do
        let(:comments_in_reverse) { true }
        it_behaves_like 'shows activities in order'
      end

      it 'can toggle between activities and comments-only' do
        expect(page).to have_selector('.work-package-details-activities-activity-contents', count: 4)
        expect(page).to have_selector('.user-comment > .message', text: note_2.notes)

        # Show only comments
        find('.activity-comments--toggler').click

        # It should remove the middle
        expect(page).to have_selector('.work-package-details-activities-activity-contents', count: 2)
        expect(page).to have_selector('.user-comment > .message', text: initial_comment)
        expect(page).to have_selector('.user-comment > .message', text: note_2.notes)

        # Show all again
        find('.activity-comments--toggler').click
        expect(page).to have_selector('.work-package-details-activities-activity-contents', count: 4)
      end

      it 'can quote a previous comment' do
        activity_tab.hover_action('1', :quote)

        field = TextEditorField.new work_package_page,
                                    'comment',
                                    selector: '.work-packages--activity--add-comment'

        expect(field.editing?).to be true

        # Add our comment
        editor = find('.ck-content')
        expect(editor).to have_selector('blockquote', text: initial_comment)

        editor.base.send_keys "\nthis is some remark under a quote"
        field.submit_by_click

        expect(page).to have_selector('.user-comment > .message', count: 3)
        expect(page).to have_selector('.user-comment > .message blockquote')
      end

      it 'can reference a changeset (Regression #30415)' do
        work_package_page.visit_tab! 'activity'
        work_package_page.ensure_page_loaded
        expect(page).to have_selector('.user-comment > .message', text: initial_comment)

        comment_field = TextEditorField.new work_package_page,
                                            'comment',
                                            selector: '.work-packages--activity--add-comment'

        comment_field.activate!
        comment_field.click_and_type_slowly "References r#{revision.revision}"
        comment_field.submit_by_click

        work_package_page.expect_comment text: "References r#{revision.revision}"
      end
    end

    context 'with no permission' do
      let(:role) do
        FactoryBot.create(:role, permissions: [:view_work_packages])
      end
      let(:user) do
        FactoryBot.create(:user,
                          member_in_project: project,
                          member_through_role: role)
      end
      let(:activities) do
        [initial_note, note_1, note_2]
      end

      context 'with ascending comments' do
        let(:comments_in_reverse) { false }
        it_behaves_like 'shows activities in order'
      end

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
