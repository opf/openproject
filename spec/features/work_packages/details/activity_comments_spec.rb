require 'spec_helper'

require 'features/work_packages/shared_contexts'
require 'features/work_packages/details/inplace_editor/shared_examples'
require 'features/work_packages/details/inplace_editor/work_package_field'
require 'features/work_packages/work_packages_page'

describe 'activity comments', js: true, selenium: true do
  let(:project) { FactoryGirl.create :project_with_types, is_public: true }
  let!(:work_package) {
    FactoryGirl.create(:work_package,
                       project: project,
                       journal_notes: initial_comment)
  }
  let(:work_packages_page) { WorkPackagesPage.new(project) }
  let(:selector) { '.work-packages--activity--add-comment' }
  let(:initial_comment) { 'the first comment in this WP' }

  before do
    login_as(user)
    allow(user.pref).to receive(:warn_on_leaving_unsaved?).and_return(false)
  end

  context 'with permission' do
    let(:user) { FactoryGirl.create :admin }
    let(:field) { WorkPackageField.new page, 'activity', selector }

    before do
      work_packages_page.visit_index(work_package)
    end

    it_behaves_like 'an auth aware field'

    describe 'submitting with other fields' do
      let(:description) { WorkPackageField.new page, 'description' }
      before do
        field.activate_edition
        field.input_element.set 'comment with description'
        description.activate_edition
        description.input_element.set 'description goes here'
      end

      it 'saves both fields from description submit' do
        description.submit_by_click
        expect(page).to have_selector('.user-comment .message', text: 'comment with description')
        description.expect_state_text('description goes here')
      end

      it 'saves both fields from comment submit' do
        field.input_element.set 'some ingenious comment.'
        field.submit_by_click
        expect(page).to have_selector('.user-comment .message', text: 'some ingenious comment.')
        description.expect_state_text('description goes here')
      end
    end

    context 'in edit state' do
      before do
        field.activate_edition
      end

      after do
        field.cancel_by_click
      end

      describe 'editing' do
        it 'buttons are disabled when empty' do
          expect(page).to have_selector("#{selector} .inplace-edit--control--save[disabled]")
        end
      end

      describe 'submitting comment' do
        it 'does not submit with enter' do
          field.input_element.set 'this is a comment'
          field.submit_by_enter

          expect(page).to_not have_selector('.user-comment .message', text: 'this is a comment')
        end

        it 'submits with click' do
          field.input_element.set 'this is a comment!1'
          field.submit_by_click

          expect(page).to have_selector('.user-comment .message', text: 'this is a comment!1')
        end

        it 'submits comments repeatedly' do
          field.input_element.set 'this is my first comment!1'
          field.submit_by_click

          expect(page).to have_selector('.user-comment > .message', count: 2)
          expect(page).to have_selector('.user-comment > .message',
                                        text: 'this is my first comment!1')

          expect(field.editing?).to be false
          field.activate_edition
          expect(field.editing?).to be true

          field.input_element.set 'this is my second comment!1'
          field.submit_by_click

          expect(page).to have_selector('.user-comment > .message', count: 3)
          expect(page).to have_selector('.user-comment > .message',
                                        text: 'this is my second comment!1')
        end
      end

      describe 'cancel comment' do
        it 'cancels with escape' do
          expect(field.editing?).to be true
          field.input_element.set 'this is a comment'
          field.cancel_by_escape
          expect(field.editing?).to be false

          expect(page).to_not have_selector('.user-comment .message', text: 'this is a comment')
        end

        it 'cancels with click' do
          expect(field.editing?).to be true
          field.input_element.set 'this is a comment'
          field.cancel_by_click
          expect(field.editing?).to be false

          expect(page).to_not have_selector('.user-comment .message', text: 'this is a comment')
        end
      end

      describe 'quoting' do
        it 'can quote a previous comment' do
          expect(page).to have_selector('.user-comment .message',
                                        text: initial_comment)

          # Hover comment
          page.find('.user-comment > .message').hover

          # Quote this comment
          page.find('.comments-icons .icon-quote').click
          expect(field.editing?).to be true

          # Add our comment
          quote = field.input_element[:value]
          expect(quote).to include("> #{initial_comment}")
          quote << "\nthis is some remark under a quote"
          field.input_element.set(quote)
          field.submit_by_click

          expect(page).to have_selector('.user-comment > .message', count: 2)
          expect(page).to have_selector('.user-comment > .message blockquote')
        end
      end
    end
  end

  context 'with no permission' do
    let(:user) { FactoryGirl.build(:user) }

    before do
      visit project_work_packages_path(project) + "/#{work_package.id}/overview"
    end

    it 'does not show the field' do
      expect(body).not_to have_selector(selector)
    end
  end
end
