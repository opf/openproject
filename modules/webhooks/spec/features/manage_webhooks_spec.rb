require 'spec_helper'

describe 'Manage webhooks through UI', type: :feature, js: true do
  before do
    login_as user
  end

  context 'as regular user' do
    let(:user) { FactoryBot.create :user }

    it 'forbids accessing the webhooks management view' do
      visit admin_outgoing_webhooks_path
      expect(page).to have_text '[Error 403]'
    end
  end

  context 'as admin' do
    let(:user) { FactoryBot.create :admin }
    let!(:project) { FactoryBot.create :project }

    it 'allows the management flow' do
      visit admin_outgoing_webhooks_path
      expect(page).to have_selector('.generic-table--empty-row')

      # Visit inline create
      find('.wp-inline-create--add-link').click

      # Fill in elements
      fill_in 'webhook_name', with: 'My webhook'
      fill_in 'webhook_url', with: 'http://example.org'

      # Check one event
      find('.form--check-box[value="work_package:created"]').set true

      # Create
      click_on 'Create'

      #
      # 1st webhook created
      #

      expect(page).to have_selector('.flash.notice', text: I18n.t(:notice_successful_create))
      expect(page).to have_selector('.webhooks--outgoing-webhook-row .name', text: 'My webhook')
      webhook = ::Webhooks::Webhook.last
      expect(webhook.event_names).to eq %w(work_package:created)
      expect(webhook.all_projects).to be_truthy

      expect(page).to have_selector('.webhooks--outgoing-webhook-row .enabled .icon-yes')
      expect(page).to have_selector('.webhooks--outgoing-webhook-row .selected_projects', text: '(all)')
      expect(page).to have_selector('.webhooks--outgoing-webhook-row .events', text: 'Work packages')
      expect(page).to have_selector('.webhooks--outgoing-webhook-row .description', text: webhook.description)

      # Edit this webhook
      find(".webhooks--outgoing-webhook-row-#{webhook.id} .icon-edit").click

      # Check the other event
      find('.form--check-box[value="work_package:created"]').set false
      find('.form--check-box[value="work_package:updated"]').set true

      # Check a subset of projects
      choose 'webhook_project_ids_selection'
      find(".webhooks--selected-project-ids[value='#{project.id}']").set true

      click_on 'Save'
      expect(page).to have_selector('.flash.notice', text: I18n.t(:notice_successful_update))
      expect(page).to have_selector('.webhooks--outgoing-webhook-row .name', text: 'My webhook')
      webhook = ::Webhooks::Webhook.last
      expect(webhook.event_names).to eq %w(work_package:updated)
      expect(webhook.projects.all).to eq [project]
      expect(webhook.all_projects).to be_falsey

      # Delete webhook
      find(".webhooks--outgoing-webhook-row-#{webhook.id} .icon-delete").click
      page.driver.browser.switch_to.alert.accept

      expect(page).to have_selector('.flash.notice', text: I18n.t(:notice_successful_delete))
      expect(page).to have_selector('.generic-table--empty-row')
    end

    context 'with existing webhook' do
      let!(:webhook) { FactoryBot.create :webhook, name: 'testing' }
      let!(:log) { FactoryBot.create :webhook_log, response_headers: { test: :foo }, webhook: webhook }

      it 'shows the delivery' do
        visit admin_outgoing_webhooks_path
        find('.webhooks--outgoing-webhook-row .name a', text: 'testing').click

        expect(page).to have_selector('.on-off-status.-enabled')
        expect(page).to have_selector('td.event_name', text: 'foo')
        expect(page).to have_selector('td.response_code', text: '200')

        # Open modal
        find('td.response_body a', text: 'Show').click

        page.within('.webhooks--response-body-modal') do
          expect(page).to have_selector('.webhooks--response-headers strong', text: 'test')
          expect(page).to have_selector('.webhooks--response-body', text: log.response_body)
        end
      end
    end
  end
end
