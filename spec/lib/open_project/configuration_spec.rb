#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe OpenProject::Configuration do
  describe '.load_config_from_file' do
    let(:config) { Hash.new }

    before do
      File.should_receive(:file?).with('file').and_return(true)
      File.should_receive(:read).and_return("
        default:

        test:
          somesetting: foo
      ")

      OpenProject::Configuration.send(:load_config_from_file, 'file', 'test', config)
    end

    it 'should merge the config from the file into the given config hash' do
      config['somesetting'].should == 'foo'
    end
  end

  describe '.load_env_from_config' do
    describe 'with a default setting' do
      let(:config) { OpenProject::Configuration.send(:load_env_from_config, {
          'default' => { 'somesetting' => 'foo' },
          'test' => {},
          'someother' => { 'somesetting' => 'bar'}
        }, 'test')}

      it 'should load a default setting' do
        config['somesetting'].should == 'foo'
      end
    end

    describe 'with an environment-specific setting' do
      let(:config) { OpenProject::Configuration.send(:load_env_from_config, {
          'default' => {},
          'test' => { 'somesetting' => 'foo' }
        }, 'test')}

      it 'should load a setting' do
        config['somesetting'].should == 'foo'
      end
    end

    describe 'with a default and an overriding environment-specific setting' do
      let(:config) { OpenProject::Configuration.send(:load_env_from_config, {
          'default' => { 'somesetting' => 'foo'},
          'test' => { 'somesetting' => 'bar' }
        }, 'test')}

      it 'should load the overriding value' do
        config['somesetting'].should == 'bar'
      end
    end
  end

  describe '.load_overrides_from_environment_variables' do
    let(:config) { {'somesetting' => 'foo'} }

    before do
      ENV['SOMESETTING'] = 'bar'
      OpenProject::Configuration.send(:load_overrides_from_environment_variables, config)
    end

    it 'should override the previous setting value' do
      expect(config['somesetting']).to eq('bar')
    end

    after do
      ENV.delete 'SOMESETTING'
    end
  end

  describe '.with' do
    before do
      OpenProject::Configuration.should_receive(:load_config_from_file) do |filename, env, config|
        config.merge!({ 'somesetting' => 'foo' })
      end
      OpenProject::Configuration.load(:env => 'test')
    end

    it 'should return the overriden the setting within the block' do
      OpenProject::Configuration['somesetting'].should == 'foo'

      OpenProject::Configuration.with 'somesetting' => 'bar' do
        OpenProject::Configuration['somesetting'].should == 'bar'
      end

      OpenProject::Configuration['somesetting'].should == 'foo'
    end
  end

  describe '.convert_old_email_settings' do
    let(:settings) { {
      "email_delivery" => {
        "delivery_method" => :smtp,
        "perform_deliveries" => true,
        "smtp_settings" => {
          "address"=>"smtp.example.net",
          "port" => 25,
          "domain" => "example.net"
      }}}
    }

    context 'with delivery_method' do
      before do
        OpenProject::Configuration.send(:convert_old_email_settings, settings,
                                        :disable_deprecation_message => true)
      end

      it 'should adopt the delivery method' do
        settings['email_delivery_method'].should == :smtp
      end

      it 'should convert smtp settings' do
        settings['smtp_address'].should == 'smtp.example.net'
        settings['smtp_port'].should == 25
        settings['smtp_domain'].should == 'example.net'
      end
    end

    context 'without delivery_method' do
      before do
        settings['email_delivery'].delete('delivery_method')
        OpenProject::Configuration.send(:convert_old_email_settings, settings,
                                        :disable_deprecation_message => true)
      end

      it 'should convert smtp settings' do
        settings['smtp_address'].should == 'smtp.example.net'
        settings['smtp_port'].should == 25
        settings['smtp_domain'].should == 'example.net'
      end
    end
  end

  describe '.configure_action_mailer' do
    let(:action_mailer) { double('ActionMailer::Base') }
    let(:config) {
      {'email_delivery_method' => 'smtp',
       'smtp_address' => 'smtp.example.net',
       'smtp_port' => '25'}
    }

    before do
      stub_const('ActionMailer::Base', action_mailer)
    end

    it 'should enable deliveries and configure ActionMailer smtp delivery' do
      action_mailer.should_receive(:perform_deliveries=).with(true)
      action_mailer.should_receive(:delivery_method=).with(:smtp)
      action_mailer.should_receive(:smtp_settings=).with({:address => 'smtp.example.net',
                                                          :port => '25'})
      OpenProject::Configuration.send(:configure_action_mailer, config)
    end
  end

end
