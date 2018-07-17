require 'spec_helper'

require 'features/work_packages/shared_contexts'
require 'features/work_packages/details/inplace_editor/shared_examples'

describe 'activity comments', js: true do
  let(:project) { FactoryBot.create :project, is_public: true }
  let!(:work_package) do
    FactoryBot.create(:work_package,
                      project: project,
                      journal_notes: initial_comment)
  end
  let(:wp_page) { Pages::SplitWorkPackage.new(work_package, project) }
  let(:selector) { '.work-packages--activity--add-comment' }
  let(:comment_field) do
    WorkPackageEditorField.new wp_page,
                               'comment',
                               selector: selector
  end
  let(:initial_comment) { 'the first comment in this WP' }

  before do
    login_as(current_user)
    allow(current_user.pref).to receive(:warn_on_leaving_unsaved?).and_return(false)
  end

  context 'with permission' do
    let(:current_user) { FactoryBot.create :admin }

    before do
      wp_page.visit!
      wp_page.ensure_page_loaded
    end

    context 'in edit state' do
      before do
        comment_field.activate!
      end

      describe 'submitting comment' do
        it 'does not submit with enter' do
          comment_field.click_and_type_slowly 'this is a comment'
          comment_field.submit_by_enter

          expect(page).to_not have_selector('.user-comment .message', text: 'this is a comment')
        end

        it 'submits with click' do
          comment_field.click_and_type_slowly 'this is a comment!1'
          comment_field.submit_by_click

          expect(page).to have_selector('.user-comment .message', text: 'this is a comment!1')
        end

        it 'submits comments repeatedly' do
          comment_field.click_and_type_slowly 'this is my first comment!1'
          comment_field.submit_by_click

          expect(page).to have_selector('.user-comment > .message', count: 2)
          expect(page).to have_selector('.user-comment > .message',
                                        text: 'this is my first comment!1')

          expect(comment_field.editing?).to be false
          comment_field.activate!
          expect(comment_field.editing?).to be true

          comment_field.click_and_type_slowly 'this is my second comment!1'
          comment_field.submit_by_click

          expect(page).to have_selector('.user-comment > .message', count: 3)
          expect(page).to have_selector('.user-comment > .message',
                                        text: 'this is my second comment!1')
        end
      end

      describe 'cancel comment' do
        it do
          expect(comment_field.editing?).to be true
          comment_field.input_element.set 'this is a comment'

          # Escape should NOT cancel the editing
          comment_field.cancel_by_escape
          expect(comment_field.editing?).to be true

          expect(page).to_not have_selector('.user-comment .message', text: 'this is a comment')

          # Click should cancel the editing
          comment_field.cancel_by_click
          expect(comment_field.editing?).to be false

          expect(page).to_not have_selector('.user-comment .message', text: 'this is a comment')
        end
      end

      describe 'autocomplete (at.js/autocompleter does not work (yet) in CKEditor)', skip: true do
        before do
        end

        describe 'work packages' do
          let!(:wp2) { FactoryBot.create(:work_package, project: project, subject: 'AutoFoo') }
          it 'autocompletes the other work package' do
            comment_field.input_element.send_keys("##{wp2.id}")
            expect(page).to have_selector('.atwho-view-ul li', text: wp2.to_s.strip)
          end
        end

        describe 'users' do
          it_behaves_like 'a principal autocomplete field' do
            let(:field) { comment_field }
          end
        end
      end

      describe 'with an existing comment' do
        it 'allows to edit an existing comment' do
          # Insert new text, need to do this separately.
          ['Comment with', ' ',  '*', '*', 'bold text', '*', '*'].each do |key|
            comment_field.input_element.send_keys key
          end
          comment_field.submit_by_click

          expect(page).to have_selector('.user-comment .message strong', text: 'bold text')
          expect(page).to have_selector('.user-comment .message', text: 'Comment with bold text')

          # Hover the new activity
          activity = page.find('#activity-2')
          page.driver.browser.action.move_to(activity.native).perform

          # Check the edit textarea
          edit_button = activity.find('.icon-edit')
          scroll_to_element(edit_button)
          edit_button.click
          edit = WorkPackageEditorField.new wp_page,
                                            'comment',
                                            selector: '.user-comment--form'

          # Insert new text, need to do this separately.
          edit.input_element.click

          [:enter, 'Comment with', ' ',  '_', 'italic text', '_', ' '].each do |key|
            edit.input_element.send_keys key
          end

          edit.submit_by_click
          expect(page).to have_selector('.user-comment .message strong', text: 'bold text')
          expect(page).to have_selector('.user-comment .message em', text: 'italic text')
        end
      end
    end

    describe 'quoting' do
      it 'can quote a previous comment' do
        expect(page).to have_selector('.user-comment .message',
                                      text: initial_comment)

        # Hover comment
        quoted = page.find('.user-comment > .message')
        scroll_to_element(quoted)
        quoted.hover

        # Quote this comment
        page.find('.comments-icons .icon-quote').click
        expect(comment_field.editing?).to be true

        # Add our comment
        expect(comment_field.input_element).to have_selector('blockquote')
        quote = comment_field.input_element[:innerHTML]
        expect(quote).to eq '<p>Anonymous wrote:</p><blockquote><p>the first comment in this WP</p></blockquote>'

        # Extend the comment
        comment_field.input_element.click

        # Insert new text, need to do this separately.
        [:enter, :return, 'this is ', '*', '*', 'a bold', '*', '*', ' remark'].each do |key|
          comment_field.input_element.send_keys key
        end

        comment_field.submit_by_click

        # Scroll to the activity
        scroll_to_element(page.find('#activity-2'))

        expect(page).to have_selector('.user-comment > .message', count: 2)
        expect(page).to have_selector('.user-comment > .message blockquote')
        expect(page).to have_selector('.user-comment > .message strong')
      end
    end
  end

  context 'with no permission' do
    let(:current_user) { FactoryBot.create(:user, member_in_project: project, member_through_role: role) }
    let(:role) { FactoryBot.create :role, permissions: %i(view_work_packages) }

    before do
      wp_page.visit!
      wp_page.ensure_page_loaded
    end

    it 'does not show the field' do
      expect(page).to have_no_selector(selector, visible: true)
    end
  end
end
