#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe OpenProject::Notifications do
  describe ".send" do
    let(:probe) { lambda { |*_args| } }
    let(:payload) { { "test" => "payload" } }

    before do
      # We can't clean this up, so we need to use a unique name
      described_class.subscribe("notifications_spec_send") do |*args, **kwargs|
        probe.call(*args, **kwargs)
      end

      allow(probe).to receive(:call)
    end

    it "delivers a notification" do
      described_class.send(:notifications_spec_send, payload)

      expect(probe).to have_received(:call) do |call_payload|
        # Don't check for object identity for the payload as it might be
        # marshalled and unmarshalled before being delivered in the future.
        expect(call_payload).to eql(payload)
      end
    end
  end

  describe ".subscribe" do
    it "throws an error when no callback is given" do
      expect do
        described_class.subscribe("notifications_spec_send")
      end.to raise_error ArgumentError, /provide a block as a callback/
    end

    describe "clear_subscriptions:" do
      let(:key) { "test_clear_subs" }
      let(:as) { [] }
      let(:bs) { [] }

      def example_with(clear_subscriptions:)
        described_class.subscribe(key) do |out|
          as << out
        end
        described_class.send(key, 1)

        described_class.subscribe(key, clear_subscriptions:) do |out|
          bs << out
        end
        described_class.send(key, 2)
      end

      context "when true" do
        before do
          example_with clear_subscriptions: true
        end

        it "clears previous subscriptions" do
          expect(as).to eq [1]
          expect(bs).to eq [2]
        end
      end

      context "when false" do
        before do
          example_with clear_subscriptions: false
        end

        it "notifies both subscriptions" do
          expect(as).to eq [1, 2]
          expect(bs).to eq [2]
        end
      end
    end
  end
end
