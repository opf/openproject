#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
        expect(Setting.find_by_name('host_name').value).to eq 'some name'
      end

      after do
        Setting.find_by_name('host_name').destroy
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
        expect(Setting.find_by_name('host_name').value).to eq 'some other name'
      end

      after do
        Setting.find_by_name('host_name').destroy
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
      expect(Setting.find_by_name('notified_events').value).to eq ['some_event']
    end

    after do
      Setting.find_by_name('notified_events').destroy
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
