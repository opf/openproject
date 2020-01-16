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

describe OpenProject::Notifications do
  let(:probe) { lambda { |*_args| } }
  let(:payload) { { 'test' => 'payload' } }

  describe '.send' do
    before do
      # We can't clean this up, so we need to use a unique name
      OpenProject::Notifications.subscribe('notifications_spec_send', &probe)

      expect(probe).to receive(:call) do |payload|
        # Don't check for object identity for the payload as it might be
        # marshalled and unmarshalled before being delivered in the future.
        expect(payload).to eql(payload)
      end
    end

    it 'should deliver a notification' do
      OpenProject::Notifications.send('notifications_spec_send', payload)
    end
  end

  describe '.subscribe' do
    it 'throws an error when no callback is given' do
      expect {
        OpenProject::Notifications.subscribe('notifications_spec_send')
      }.to raise_error ArgumentError, /provide a block as a callback/
    end

    describe 'clear_subscriptions:' do
      let(:key) { 'test_clear_subs' }
      let(:as) { [] }
      let(:bs) { [] }

      def example_with(clear:)
        OpenProject::Notifications.subscribe(key) do |out|
          as << out
        end
        OpenProject::Notifications.send(key, 1)

        OpenProject::Notifications.subscribe(key, clear_subscriptions: clear) do |out|
          bs << out
        end
        OpenProject::Notifications.send(key, 2)
      end

      context 'true' do
        before do
          example_with clear: true
        end

        it 'clears previous subscriptions' do
          expect(as).to eq [1]
          expect(bs).to eq [2]
        end
      end

      context 'false' do
        before do
          example_with clear: false
        end

        it 'notifies both subscriptions' do
          expect(as).to eq [1, 2]
          expect(bs).to eq [2]
        end
      end
    end
  end
end
