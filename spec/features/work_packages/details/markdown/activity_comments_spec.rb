require 'spec_helper'

require 'features/work_packages/shared_contexts'
require 'features/work_packages/details/inplace_editor/shared_examples'

describe 'activity comments', js: true, with_mail: false do
  let(:project) { FactoryBot.create :project, public: true }
  let!(:work_package) do
    FactoryBot.create(:work_package,
                      project: project,
                      journal_notes: initial_comment)
  end
  let(:wp_page) { Pages::SplitWorkPackage.new(work_package, project) }
  let(:selector) { '.work-packages--activity--add-comment' }
  let(:comment_field) do
    TextEditorField.new wp_page,
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

          expect(page).to have_no_selector('.user-comment .message', text: 'this is a comment')
        end

        it 'submits with click' do
          comment_field.click_and_type_slowly 'this is a comment!1'
          comment_field.submit_by_click

          wp_page.expect_comment text: 'this is a comment!1'
        end

        it 'submits comments repeatedly' do
          comment_field.click_and_type_slowly 'this is my first comment!1'
          comment_field.submit_by_click

          expect(page).to have_selector('.user-comment > .message', count: 2)
          wp_page.expect_comment text: 'this is my first comment!1'

          expect(comment_field.editing?).to be false
          comment_field.activate!
          expect(comment_field.editing?).to be true

          comment_field.click_and_type_slowly 'this is my second comment!1'
          comment_field.submit_by_click

          expect(page).to have_selector('.user-comment > .message', count: 3)
          wp_page.expect_comment text: 'this is my second comment!1'
        end
      end

      describe 'cancel comment' do
        it do
          expect(comment_field.editing?).to be true
          comment_field.input_element.set 'this is a comment'

          # Escape should NOT cancel the editing
          comment_field.cancel_by_escape
          expect(comment_field.editing?).to be true

          expect(page).to have_no_selector('.user-comment .message', text: 'this is a comment')

          # Click should cancel the editing
          comment_field.cancel_by_click
          expect(comment_field.editing?).to be false

          expect(page).to have_no_selector('.user-comment .message', text: 'this is a comment')
        end
      end

      describe 'autocomplete' do
        describe 'work packages' do
          let!(:wp2) { FactoryBot.create(:work_package, project: project, subject: 'AutoFoo') }

          it 'can move to the work package by click (Regression #30928)' do
            comment_field.input_element.send_keys("##{wp2.id}")
            expect(page).to have_selector('.mention-list-item', text: wp2.to_s.strip)

            comment_field.submit_by_click
            page.find('#activity-2 a.issue', text: wp2.id).click

            other_wp_page = ::Pages::FullWorkPackage.new wp2
            other_wp_page.ensure_page_loaded
            other_wp_page.edit_field(:subject).expect_text 'AutoFoo'
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
          # Insert new text, need to do this separately.''
          ['Comment with', ' ', '*', '*', 'bold text', '*', '*', ' ', 'in it'].each do |key|
            comment_field.input_element.send_keys key
          end
          comment_field.submit_by_click

          wp_page.expect_comment text: 'Comment with bold text in it'
          wp_page.expect_comment text: 'bold text', subselector: 'strong'

          # Hover the new activity
          activity = page.find('#activity-2')
          page.driver.browser.action.move_to(activity.native).perform

          # Check the edit textarea
          edit_button = activity.find('.icon-edit')
          scroll_to_element(edit_button)
          edit_button.click
          edit = TextEditorField.new wp_page,
                                     'comment',
                                     selector: '.user-comment--form'

          # Insert new text, need to do this separately.
          edit.input_element.click

          [:enter, 'Comment with', ' ',  '_', 'italic text', '_', ' ', 'in it'].each do |key|
            edit.input_element.send_keys key
          end

          edit.submit_by_click
          wp_page.expect_comment text: 'Comment with italic text in it'
          wp_page.expect_comment text: 'italic text', subselector: 'em'
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

        comment_field.ckeditor.click_and_type_slowly :enter

        # Insert new text, need to do this separately.
        comment_field.ckeditor.click_and_type_slowly :return, 'this is ', '*', '*', 'a bold', '*', '*', ' remark'

        comment_field.submit_by_click

        # Scroll to the activity
        scroll_to_element(page.find('#activity-2'))

        wp_page.expect_comment text: 'this is a bold remark'
        wp_page.expect_comment count: 2
        wp_page.expect_comment subselector: 'blockquote'
        wp_page.expect_comment subselector: 'strong', text: 'a bold'
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
