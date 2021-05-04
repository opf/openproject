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

  describe '.convert_old_email_settings' do
    let(:settings) do
      {
        'email_delivery' => {
          'delivery_method' => :smtp,
          'perform_deliveries' => true,
          'smtp_settings' => {
            'address' => 'smtp.example.net',
            'port' => 25,
            'domain' => 'example.net'
          }
        }
      }
    end

    context 'with delivery_method' do
      before do
        OpenProject::Configuration.send(:convert_old_email_settings,
                                        settings,
                                        disable_deprecation_message: true)
      end

      it 'should adopt the delivery method' do
        expect(settings['email_delivery_method']).to eq(:smtp)
      end

      it 'should convert smtp settings' do
        expect(settings['smtp_address']).to eq('smtp.example.net')
        expect(settings['smtp_port']).to eq(25)
        expect(settings['smtp_domain']).to eq('example.net')
      end
    end

    context 'without delivery_method' do
      before do
        settings['email_delivery'].delete('delivery_method')
        OpenProject::Configuration.send(:convert_old_email_settings, settings,
                                        disable_deprecation_message: true)
      end

      it 'should convert smtp settings' do
        expect(settings['smtp_address']).to eq('smtp.example.net')
        expect(settings['smtp_port']).to eq(25)
        expect(settings['smtp_domain']).to eq('example.net')
      end
    end
  end

  describe '.migrate_mailer_configuration!' do
    it 'does nothing if no legacy configuration given' do
      OpenProject::Configuration['email_delivery_method'] = nil
      expect(Setting).to_not receive(:email_delivery_method=)
      expect(OpenProject::Configuration.migrate_mailer_configuration!).to eq(true)
    end

    it 'does nothing if email_delivery_configuration forced to legacy' do
      OpenProject::Configuration['email_delivery_configuration'] = 'legacy'
      expect(Setting).to_not receive(:email_delivery_method=)
      expect(OpenProject::Configuration.migrate_mailer_configuration!).to eq(true)
    end

    it 'does nothing if setting already set' do
      OpenProject::Configuration['email_delivery_method'] = :sendmail
      Setting.email_delivery_method = :sendmail
      expect(Setting).to_not receive(:email_delivery_method=)
      expect(OpenProject::Configuration.migrate_mailer_configuration!).to eq(true)
    end

    it 'migrates the existing configuration to the settings table' do
      OpenProject::Configuration['email_delivery_method'] = :smtp
      OpenProject::Configuration['smtp_password'] = 'p4ssw0rd'
      OpenProject::Configuration['smtp_address'] = 'smtp.example.com'
      OpenProject::Configuration['smtp_port'] = 587
      OpenProject::Configuration['smtp_user_name'] = 'username'
      OpenProject::Configuration['smtp_enable_starttls_auto'] = true
      OpenProject::Configuration['smtp_ssl'] = true

      expect(OpenProject::Configuration.migrate_mailer_configuration!).to eq(true)
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
      OpenProject::Configuration['email_delivery_configuration'] = 'legacy'
      expect(OpenProject::Configuration).to receive(:configure_legacy_action_mailer)
      OpenProject::Configuration.reload_mailer_configuration!
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
      OpenProject::Configuration.reload_mailer_configuration!
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
      OpenProject::Configuration.reload_mailer_configuration!
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
      OpenProject::Configuration.reload_mailer_configuration!
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
      OpenProject::Configuration.reload_mailer_configuration!
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

    it 'should enable deliveries and configure ActionMailer smtp delivery' do
      expect(action_mailer).to receive(:perform_deliveries=).with(true)
      expect(action_mailer).to receive(:delivery_method=).with(:smtp)
      expect(action_mailer).to receive(:smtp_settings=).with(address: 'smtp.example.net',
                                                             port: '25')
      OpenProject::Configuration.send(:configure_legacy_action_mailer)
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
          OpenProject::Configuration['rails_cache_store'] = 'bar'
        end

        it 'changes the cache store' do
          OpenProject::Configuration.send(:configure_cache, application_config)
          expect(application_config.cache_store).to eq([:bar])
        end
      end

      context 'without additional cache store configuration' do
        before do
          OpenProject::Configuration['rails_cache_store'] = nil
        end

        it 'does not change the cache store' do
          OpenProject::Configuration.send(:configure_cache, application_config)
          expect(application_config.cache_store).to eq('foo')
        end
      end
    end

    context 'without cache store already set' do
      before do
        application_config.cache_store = nil
      end

      context 'with additional cache store configuration' do
        before do
          OpenProject::Configuration['rails_cache_store'] = 'bar'
        end

        it 'changes the cache store' do
          OpenProject::Configuration.send(:configure_cache, application_config)
          expect(application_config.cache_store).to eq([:bar])
        end
      end

      context 'without additional cache store configuration' do
        before do
          OpenProject::Configuration['rails_cache_store'] = nil
        end
        it 'defaults the cache store to :file_store' do
          OpenProject::Configuration.send(:configure_cache, application_config)
          expect(application_config.cache_store.first).to eq(:file_store)
        end
      end
    end
  end

  context 'helpers' do
    describe '#direct_uploads?' do
      let(:value) { OpenProject::Configuration.direct_uploads? }

      it 'should be false by default' do
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

        context 'AWS', with_config: storage('AWS') do
          it 'should be true' do
            expect(value).to be true
          end
        end

        context 'Azure', with_config: storage('azure') do
          it 'should be false' do
            expect(value).to be false
          end
        end
      end
    end
  end
end
