#-- encoding: UTF-8
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

describe Setting do

  # OpenProject specific defaults that are set in settings.yml
  describe "OpenProject's default settings" do
    it "has OpenProject as application title" do
      expect(Setting.app_title).to eq "OpenProject"
    end

    it "allows users to register themselves" do
      expect(Setting.self_registration?).to be_true
    end

    it "allows anonymous users to access public information" do
      expect(Setting.login_required?).to be_false
    end
  end

  # checks whether settings can be set and are persisted in the database
  describe "changing a setting" do
    context "setting doesn't exist in the database" do
      before do
        Setting.destroy_all
        Setting.host_name = "some name"
      end

      it "sets the setting" do
        expect(Setting.host_name).to eq "some name"
      end

      it "stores the setting" do
        expect(Setting.find_by_name('host_name').value).to eq "some name"
      end
    end

    context "setting already exist in the database" do
      before do
        Setting.host_name = "some name"
        Setting.host_name = "some other name"
      end

      it "sets the setting" do
        expect(Setting.host_name).to eq "some other name"
      end

      it "stores the setting" do
        expect(Setting.find_by_name('host_name').value).to eq "some other name"
      end
    end
  end

  # tests the serialization feature to store complex data types like arrays in settings
  describe "serialized settings" do
    it "serializes arrays" do
      # note: notified_events is marked as serialized in settings.yml (no type-based automagic here)
      Setting.notified_events = ['some_event']
      expect(Setting.notified_events).to eq ['some_event']
      expect(Setting.find_by_name('notified_events').value).to eq ['some_event']
    end
  end

  # tests stuff regarding settings callbacks
  describe "callbacks" do
    # collects data for the dummy callback
    let(:collector) { [] }

    # a dummy callback that collects data
    let(:callback)  { lambda { |value| collector << value } }

    # registers the dummy callback
    before do
      Setting.clear_callbacks
      Setting.register_callback(:notified_events, &callback)
    end

    it "calls a callback when a setting is set" do
      Setting.notified_events = [:some_event]
      expect(collector).to_not be_empty
    end

    it "calls no callback on invalid setting" do
      Setting.any_instance.stub(:valid?).and_return(false)
      Setting.notified_events = 'invalid'
      expect(collector).to be_empty
    end

    it "calls multiple callbacks when a setting is set" do
      Setting.notified_events = [:some_event]
      Setting.notified_events = [:some_event]
      expect(collector.size).to eq 2
    end

    it "calls only the callbacks belonging to the changed setting" do
      Setting.register_callback(:host_name, &callback)
      Setting.notified_events = [:some_event]
      expect(collector.size).to eq 1
    end

    it "can clear all callbacks" do
      Setting.clear_callbacks
      Setting.notified_events = [:some_event]
      expect(collector).to be_empty
    end

    it "attaches to the right setting by passing a string" do
      Setting.clear_callbacks
      Setting.register_callback('notified_events', &callback)
      Setting.notified_events = [:some_event]
      expect(collector).to_not be_empty
    end

    it "passes the new setting value to the callback" do
      Setting.notified_events = [:some_event]
      expect(collector).to include [:some_event]
    end

    it "optionally passes the old setting value to the callback as the second argument" do
      Setting.host_name = 'some name' # set old value
      cb = lambda { |_, old_value| collector << old_value }
      Setting.register_callback(:host_name, &cb)
      Setting.host_name = 'some other name'
      expect(collector).to include 'some name'
    end

    it "optionally passes the setting name to the callback as the third argument" do
      cb = lambda { |_, _, name| collector << name }
      Setting.register_callback(:host_name, &cb)
      Setting.host_name = 'some name'
      expect(collector).to include :host_name
    end

    # the callback object can be any object that responds to #call
    describe "callback object" do
      # returns a callback object with three different signatures for #call
      def callback_object(callback_method = :call_1)
        Struct.new(:collector) {
          def call_1(value)
            self.collector << value;
          end
          def call_2(value, old_value)
            self.collector << old_value;
          end
          def call_3(value, old_value, name);
            self.collector << name
          end
          alias_method :call, callback_method
        }.new(collector)
      end

      before { Setting.clear_callbacks }

      it "takes a callback object" do
        Setting.register_callback(:notified_events, callback_object)
        Setting.notified_events = [:some_event]
        expect(collector).to include [:some_event]
      end

      it "takes a callback object that responds to call with two parameters" do
        Setting.notified_events = [:initial_value] # set old value
        Setting.register_callback(:notified_events, callback_object(:call_2))
        Setting.notified_events = [:some_event]
        expect(collector).to include [:initial_value]
      end

      it "takes a callback object that responds to call with three parameters" do
        Setting.register_callback(:notified_events, callback_object(:call_3))
        Setting.notified_events = [:some_event]
        expect(collector).to include :notified_events
      end
    end

    # tests proper throwing of exceptions
    describe "exception" do
      it "throws an error when setting name is missing" do
        expect { Setting.register_callback }.to raise_error ArgumentError, /wrong number of arguments/
      end

      it "throws an error when no callback is given" do
        expect {
          Setting.register_callback(:notified_events)
        }.to raise_error ArgumentError, /provide either a block or a callback object/
      end

      it "throws an error when callback object doesn't respond to #call" do
        expect {
          Setting.register_callback(:notified_events, Object.new)
        }.to raise_error ArgumentError, /provide a callback object that responds to #call/
      end

      # currently, optional parameters in callback objects aren't supported
      it "throws an error when callback object takes optional parameters" do
        cb = Class.new { def call(value, old_value = nil, name = nil); end }.new
        expect {
          Setting.register_callback(:notified_events, cb)
        }.to raise_error ArgumentError, /must not take optional parameters/
      end
    end
  end

end
