#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe OpenProject::Configuration do
  let!(:definitions_before) { Settings::Definition.all.dup }

  before do
    Settings::Definition.send(:reset)
  end

  after do
    Settings::Definition.send(:reset)
    Settings::Definition.instance_variable_set(:@all, definitions_before)
    Setting.clear_cache
  end

  describe '.migrate_mailer_configuration!' do
    before do
      allow(Setting)
        .to receive(:email_delivery_method=)
    end

    it 'does nothing if no legacy configuration given' do
      described_class['email_delivery_method'] = nil
      expect(Setting).not_to have_received(:email_delivery_method=)
      expect(described_class.migrate_mailer_configuration!).to eq(true)
    end

    it 'does nothing if email_delivery_configuration forced to legacy' do
      described_class['email_delivery_configuration'] = 'legacy'
      expect(Setting).not_to have_received(:email_delivery_method=)
      expect(described_class.migrate_mailer_configuration!).to eq(true)
    end

    it 'does nothing if setting already set' do
      described_class['email_delivery_method'] = :sendmail
      allow(Setting)
        .to receive(:email_delivery_method)
              .and_return(:sendmail)
      expect(Setting).not_to have_received(:email_delivery_method=)
      expect(described_class.migrate_mailer_configuration!).to eq(true)
    end

    it 'migrates the existing configuration to the settings table' do
      described_class['email_delivery_method'] = :smtp
      described_class['smtp_password'] = 'p4ssw0rd'
      described_class['smtp_address'] = 'smtp.example.com'
      described_class['smtp_port'] = 587
      described_class['smtp_user_name'] = 'username'
      described_class['smtp_enable_starttls_auto'] = true
      described_class['smtp_ssl'] = true

      expect(described_class.migrate_mailer_configuration!).to eq(true)
      expect(Setting.email_delivery_method).to eq(:smtp)
      expect(Setting.smtp_password).to eq('p4ssw0rd')
      expect(Setting.smtp_address).to eq('smtp.example.com')
      expect(Setting.smtp_port).to eq(587)
      expect(Setting.smtp_user_name).to eq('username')
      expect(Setting.smtp_enable_starttls_auto?).to eq(true)
      expect(Setting.smtp_ssl?).to eq(true)
    end
  end

  describe '.reload_mailer_configuration!' do
    let(:action_mailer) { double('ActionMailer::Base', smtp_settings: {}, deliveries: []) }

    before do
      stub_const('ActionMailer::Base', action_mailer)
    end

    it 'uses the legacy method to configure email settings' do
      described_class['email_delivery_configuration'] = 'legacy'
      expect(OpenProject::Configuration).to receive(:configure_legacy_action_mailer)
      described_class.reload_mailer_configuration!
    end

    it 'allows settings smtp_authentication to none' do
      Setting.email_delivery_method = :smtp
      Setting.smtp_authentication = :none
      Setting.smtp_password = 'old'
      Setting.smtp_address = 'smtp.example.com'
      Setting.smtp_domain = 'example.com'
      Setting.smtp_port = 25
      Setting.smtp_user_name = 'username'
      Setting.smtp_enable_starttls_auto = 1
      Setting.smtp_ssl = 0

      expect(action_mailer).to receive(:perform_deliveries=).with(true)
      expect(action_mailer).to receive(:delivery_method=).with(:smtp)
      described_class.reload_mailer_configuration!
      expect(action_mailer.smtp_settings[:smtp_authentication]).to be_nil
      expect(action_mailer.smtp_settings).to eq(address: 'smtp.example.com',
                                                port: 25,
                                                domain: 'example.com',
                                                enable_starttls_auto: true,
                                                ssl: false)

      Setting.email_delivery_method = :smtp
      Setting.smtp_authentication = :none
      Setting.smtp_password = 'old'
      Setting.smtp_address = 'smtp.example.com'
      Setting.smtp_domain = 'example.com'
      Setting.smtp_port = 25
      Setting.smtp_user_name = 'username'
      Setting.smtp_enable_starttls_auto = 0
      Setting.smtp_ssl = 1

      expect(action_mailer).to receive(:perform_deliveries=).with(true)
      expect(action_mailer).to receive(:delivery_method=).with(:smtp)
      described_class.reload_mailer_configuration!
      expect(action_mailer.smtp_settings[:smtp_authentication]).to be_nil
      expect(action_mailer.smtp_settings).to eq(address: 'smtp.example.com',
                                                port: 25,
                                                domain: 'example.com',
                                                enable_starttls_auto: false,
                                                ssl: true)
    end

    it 'correctly sets the action mailer configuration based on the settings' do
      Setting.email_delivery_method = :smtp
      Setting.smtp_password = 'p4ssw0rd'
      Setting.smtp_address = 'smtp.example.com'
      Setting.smtp_domain = 'example.com'
      Setting.smtp_port = 587
      Setting.smtp_user_name = 'username'
      Setting.smtp_enable_starttls_auto = 1
      Setting.smtp_ssl = 0

      expect(action_mailer).to receive(:perform_deliveries=).with(true)
      expect(action_mailer).to receive(:delivery_method=).with(:smtp)
      described_class.reload_mailer_configuration!
      expect(action_mailer.smtp_settings).to eq(address: 'smtp.example.com',
                                                port: 587,
                                                domain: 'example.com',
                                                authentication: 'plain',
                                                user_name: 'username',
                                                password: 'p4ssw0rd',
                                                enable_starttls_auto: true,
                                                ssl: false)

      Setting.email_delivery_method = :smtp
      Setting.smtp_password = 'p4ssw0rd'
      Setting.smtp_address = 'smtp.example.com'
      Setting.smtp_domain = 'example.com'
      Setting.smtp_port = 587
      Setting.smtp_user_name = 'username'
      Setting.smtp_enable_starttls_auto = 0
      Setting.smtp_ssl = 1

      expect(action_mailer).to receive(:perform_deliveries=).with(true)
      expect(action_mailer).to receive(:delivery_method=).with(:smtp)
      described_class.reload_mailer_configuration!
      expect(action_mailer.smtp_settings).to eq(address: 'smtp.example.com',
                                                port: 587,
                                                domain: 'example.com',
                                                authentication: 'plain',
                                                user_name: 'username',
                                                password: 'p4ssw0rd',
                                                enable_starttls_auto: false,
                                                ssl: true)
    end
  end

  describe '.configure_legacy_action_mailer' do
    let(:action_mailer) { double('ActionMailer::Base', deliveries: []) }
    let(:settings) do
      { 'email_delivery_method' => 'smtp',
        'smtp_address' => 'smtp.example.net',
        'smtp_port' => '25' }.map do |name, value|
        OpenStruct.new name: name, value: value
      end
    end

    before do
      allow(Settings::Definition)
        .to receive(:[]) do |name|
        settings.detect { |s| s.name == name }
      end

      allow(Settings::Definition)
        .to receive(:all_of_prefix) do |prefix|
        settings.select { |s| s.name.start_with?(prefix) }
      end

      stub_const('ActionMailer::Base', action_mailer)
    end

    it 'enables deliveries and configure ActionMailer smtp delivery' do
      expect(action_mailer).to receive(:perform_deliveries=).with(true)
      expect(action_mailer).to receive(:delivery_method=).with(:smtp)
      expect(action_mailer).to receive(:smtp_settings=).with(address: 'smtp.example.net',
                                                             port: '25')
      described_class.send(:configure_legacy_action_mailer)
    end
  end

  describe '.configure_cache' do
    let(:application_config) do
      Rails::Application::Configuration.new Rails.root
    end

    context 'with cache store already set' do
      before do
        application_config.cache_store = 'foo'
      end

      context 'with additional cache store configuration' do
        before do
          described_class['rails_cache_store'] = 'bar'
        end

        it 'changes the cache store' do
          described_class.send(:configure_cache, application_config)
          expect(application_config.cache_store).to eq([:bar])
        end
      end

      context 'without additional cache store configuration' do
        before do
          described_class['rails_cache_store'] = nil
        end

        it 'does not change the cache store' do
          described_class.send(:configure_cache, application_config)
          expect(application_config.cache_store).to eq('foo')
        end
      end
    end

    context 'without cache store already set' do
      before do
        application_config.cache_store = nil
        described_class.send(:configure_cache, application_config)
      end

      context 'with additional cache store configuration', with_config: { 'rails_cache_store' => 'bar' } do
        it 'changes the cache store' do
          expect(application_config.cache_store).to eq([:bar])
        end
      end

      context 'without additional cache store configuration', with_config: { 'rails_cache_store' => nil } do
        it 'defaults the cache store to :file_store' do
          expect(application_config.cache_store.first).to eq(:file_store)
        end
      end
    end
  end

  describe '#direct_uploads?' do
    let(:value) { described_class.direct_uploads? }

    it 'is false by default' do
      expect(value).to be false
    end

    context 'with remote storage' do
      def self.storage(provider)
        {
          attachments_storage: :fog,
          fog: {
            credentials: {
              provider: provider
            }
          }
        }
      end

      context 'with AWS', with_config: storage('AWS') do
        it 'is true' do
          expect(value).to be true
        end
      end

      context 'with Azure', with_config: storage('azure') do
        it 'is false' do
          expect(value).to be false
        end
      end
    end
  end
end
