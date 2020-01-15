#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

describe Setting, type: :model do
  # OpenProject specific defaults that are set in settings.yml
  describe "OpenProject's default settings" do
    it 'has OpenProject as application title' do
      expect(Setting.app_title).to eq 'OpenProject'
    end

    it 'allows users to register themselves' do
      expect(Setting.self_registration?).to be_truthy
    end

    it 'allows anonymous users to access public information' do
      expect(Setting.login_required?).to be_falsey
    end
  end

  # checks whether settings can be set and are persisted in the database
  describe 'changing a setting' do
    context "setting doesn't exist in the database" do
      before do
        Setting.host_name = 'some name'
      end

      it 'sets the setting' do
        expect(Setting.host_name).to eq 'some name'
      end

      it 'stores the setting' do
        expect(Setting.find_by(name: 'host_name').value).to eq 'some name'
      end

      after do
        Setting.find_by(name: 'host_name').destroy
      end
    end

    context 'setting already exist in the database' do
      before do
        Setting.host_name = 'some name'
        Setting.host_name = 'some other name'
      end

      it 'sets the setting' do
        expect(Setting.host_name).to eq 'some other name'
      end

      it 'stores the setting' do
        expect(Setting.find_by(name: 'host_name').value).to eq 'some other name'
      end

      after do
        Setting.find_by(name: 'host_name').destroy
      end
    end
  end

  describe ".installation_uuid" do
    after do
      Setting.find_by(name: "installation_uuid")&.destroy
    end

    it "returns unknown if the settings table isn't available yet" do
      allow(Setting)
        .to receive(:settings_table_exists_yet?)
        .and_return(false)
      expect(Setting.installation_uuid).to eq("unknown")
    end

    context "with settings table ready" do
      it "resets the value if blank" do
        Setting.create!(name: "installation_uuid", value: "")
        expect(Setting.installation_uuid).not_to be_blank
      end

      it "returns the existing value if any" do
        # can't use with_settings since Setting.installation_uuid has a custom implementation
        allow(Setting).to receive(:installation_uuid).and_return "abcd1234"

        expect(Setting.installation_uuid).to eq("abcd1234")
      end

      context "with no existing value" do
        context "in test environment" do
          before do
            expect(Rails.env).to receive(:test?).and_return(true)
          end

          it "returns 'test' as the UUID" do
            expect(Setting.installation_uuid).to eq("test")
          end
        end

        it "returns a random UUID" do
          expect(Rails.env).to receive(:test?).and_return(false)
          installation_uuid = Setting.installation_uuid
          expect(installation_uuid).not_to eq("test")
          expect(installation_uuid.size).to eq(36)
          expect(Setting.installation_uuid).to eq(installation_uuid)
        end
      end
    end
  end

  # Check that when reading certain setting values that they get overwritten if needed.
  describe "filter saved settings" do
    before do
      Setting.work_package_list_default_highlighting_mode = "inline"
    end

    describe "with EE token", with_ee: [:conditional_highlighting] do
      it "returns the value for 'work_package_list_default_highlighting_mode' without changing it" do
        expect(Setting.work_package_list_default_highlighting_mode).to eq("inline")
      end
    end

    describe "without EE" do
      it "return 'none' as 'work_package_list_default_highlighting_mode'" do
        expect(Setting.work_package_list_default_highlighting_mode).to eq("none")
      end
    end
  end

  # tests the serialization feature to store complex data types like arrays in settings
  describe 'serialized settings' do
    before do
      # note: notified_events is marked as serialized in settings.yml (no type-based automagic here)
      Setting.notified_events = ['some_event']
    end

    it 'serializes arrays' do
      expect(Setting.notified_events).to eq ['some_event']
      expect(Setting.find_by(name: 'notified_events').value).to eq ['some_event']
    end

    after do
      Setting.find_by(name: 'notified_events').destroy
    end
  end

  describe 'caching' do
    let(:cache_key) { Setting.send :cache_key }

    before do
      RequestStore.clear!
      Rails.cache.clear
    end

    after do
      RequestStore.clear!
      Rails.cache.clear
    end

    context 'cache is empty' do
      it 'requests the settings once from database' do
        expect(Setting).to receive(:pluck).with(:name, :value)
          .once
          .and_call_original

        expect(Rails.cache).to receive(:fetch).once.and_call_original
        expect(RequestStore).to receive(:fetch).exactly(3).times.and_call_original

        # Settings are empty by default
        expect(RequestStore.read(:cached_settings)).to be_nil
        expect(Rails.cache.read(cache_key)).to be_nil

        # Falls back to default values, but hitting cache
        value = Setting.app_title
        expect(Setting.app_title).to eq 'OpenProject'
        expect(value).to eq(Setting.app_title)

        # Settings are empty by default
        expect(RequestStore.read(:cached_settings)).to eq({})
        expect(Rails.cache.read(cache_key)).to eq({})
      end

      it 'clears the cache when writing a setting' do
        expect(Setting.app_title).to eq 'OpenProject'
        expect(RequestStore.read(:cached_settings)).to eq({})

        new_title = 'OpenProject with changed title'
        Setting.app_title = new_title
        expect(RequestStore.read(:cached_settings)).to be_nil
        expect(Rails.cache.read(cache_key)).to be_nil

        expect(Setting.app_title).to eq(new_title)
        expect(Setting.count).to eq(1)
        expect(RequestStore.read(:cached_settings)).to eq('app_title' => new_title)
      end
    end

    context 'cache is not empty' do
      let(:cached_hash) {
        { 'available_languages' => "---\n- en\n- de\n" }
      }

      before do
        Rails.cache.write(cache_key, cached_hash)
      end

      it 'returns the value from the deeper cache' do
        expect(RequestStore.read(:cached_settings)).to be_nil
        expect(Setting.available_languages).to eq(%w(en de))

        expect(RequestStore.read(:cached_settings)).to eq(cached_hash)
      end

      it 'expires the cache when writing a setting' do
        Setting.available_languages = %w(en)
        expect(RequestStore.read(:cached_settings)).to be_nil

        # Creates a new cache key
        new_cache_key = Setting.send(:cache_key)
        new_hash = { 'available_languages' => "---\n- en\n" }
        expect(new_cache_key).not_to be eq(cache_key)

        # No caching is done until first read
        expect(RequestStore.read(:cached_settings)).to be_nil
        expect(Rails.cache.read(cache_key)).to be_nil
        expect(Rails.cache.read(new_cache_key)).to be_nil

        expect(Setting.available_languages).to eq(%w(en))
        expect(Rails.cache.read(new_cache_key)).to eq(new_hash)
        expect(RequestStore.read(:cached_settings)).to eq(new_hash)
      end
    end
  end

  # tests stuff regarding settings callbacks
  describe 'callbacks' do
    # collects data for the dummy callback
    let(:collector) { [] }

    # a dummy callback that collects data
    let(:callback)  { lambda { |args| collector << args[:value] } }

    # registers the dummy callback
    before do
      Setting.register_callback(:notified_events, &callback)
    end

    it 'calls a callback when a setting is set' do
      Setting.notified_events = [:some_event]
      expect(collector).not_to be_empty
    end

    it 'calls no callback on invalid setting' do
      allow_any_instance_of(Setting).to receive(:valid?).and_return(false)
      Setting.notified_events = 'invalid'
      expect(collector).to be_empty
    end

    it 'calls multiple callbacks when a setting is set' do
      Setting.register_callback(:notified_events, &callback)
      Setting.notified_events = [:some_event]
      expect(collector.size).to eq 2
    end

    it 'calls callbacks every time a setting is set' do
      Setting.notified_events = [:some_event]
      Setting.notified_events = [:some_event]
      expect(collector.size).to eq 2
    end

    it 'calls only the callbacks belonging to the changed setting' do
      Setting.register_callback(:host_name, &callback)
      Setting.notified_events = [:some_event]
      expect(collector.size).to eq 1
    end

    it 'attaches to the right setting by passing a string' do
      Setting.register_callback('app_title', &callback)
      Setting.app_title = 'some title'
      expect(collector).not_to be_empty
    end

    it 'passes the new setting value to the callback' do
      Setting.notified_events = [:some_event]
      expect(collector).to include [:some_event]
    end

    it 'optionally passes the old setting value to the callback as the second argument' do
      Setting.host_name = 'some name' # set old value
      cb = lambda { |args| collector << args[:old_value] }
      Setting.register_callback(:host_name, &cb)
      Setting.host_name = 'some other name'
      expect(collector).to include 'some name'
    end

    after do
      Setting.destroy_all
    end
  end
end
