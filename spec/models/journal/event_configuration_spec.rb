# frozen_string_literal: true

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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Journal::EventConfiguration do
  describe ".with" do
    let!(:trigger_callbacks_before) { described_class.active? }
    let!(:proc_called_counter) { OpenStruct.new called: false, trigger_callbacks: trigger_callbacks_before } # rubocop:disable Style/OpenStructUse
    let(:proc) do
      Proc.new do
        proc_called_counter.called = true
        proc_called_counter.trigger_callbacks = described_class.active?
      end
    end

    it "executes the block" do
      described_class.with !trigger_callbacks_before, &proc

      expect(proc_called_counter.called)
        .to be_truthy
    end

    it "uses the provided trigger_callbacks value within the proc" do
      described_class.with !trigger_callbacks_before, &proc

      expect(proc_called_counter.trigger_callbacks)
        .to eql !trigger_callbacks_before
    end

    it "resets the trigger_callbacks to the value before" do
      described_class.with !trigger_callbacks_before, &proc

      expect(described_class.active?)
        .to eql trigger_callbacks_before
    end

    context "when called with nil" do
      it "defaults to true for trigger_callbacks" do
        described_class.with nil, &proc
        expect(described_class.active?)
          .to be(true)
      end
    end

    context "with nested calls" do
      before do
        allow(Rails.logger).to receive(:debug)

        described_class.with outer_call_value do
          described_class.with inner_call_value, &proc
        end
      end

      context "when trigger_callbacks value of inner call is different from outer call" do
        let(:outer_call_value) { !trigger_callbacks_before }
        let(:inner_call_value) { trigger_callbacks_before }

        it "executes the block" do
          expect(proc_called_counter.called)
            .to be_truthy
        end

        it "lets the outer block call dominate further block calls" do
          expect(proc_called_counter.trigger_callbacks)
            .to eq(outer_call_value)
        end

        it "logs a debug message" do
          expect(Rails.logger).to have_received(:debug)
            .with("Ignoring setting journal event callbacks to '#{inner_call_value}' " \
                  "as a parent block already set it to #{outer_call_value}")
        end
      end

      context "when trigger_callbacks value of inner call is the same as for outer call" do
        let(:outer_call_value) { !trigger_callbacks_before }
        let(:inner_call_value) { outer_call_value }

        it "does not log any debug messages" do
          expect(Rails.logger).not_to have_received(:debug)
        end
      end

      context "when trigger_callbacks value of inner call is nil" do
        let(:outer_call_value) { !trigger_callbacks_before }
        let(:inner_call_value) { nil }

        it "executes the block" do
          expect(proc_called_counter.called)
            .to be_truthy
        end

        it "keeps the value of the outer block call" do
          expect(proc_called_counter.trigger_callbacks)
            .to eq(outer_call_value)
        end

        it "does not log any debug messages" do
          expect(Rails.logger).not_to have_received(:debug)
        end
      end

      context "when trigger_callbacks value of outer call is nil" do
        let(:outer_call_value) { nil }
        let(:inner_call_value) { !trigger_callbacks_before }

        it "executes the block" do
          expect(proc_called_counter.called)
            .to be_truthy
        end

        it "sets the value to the inner block call value" do
          expect(proc_called_counter.trigger_callbacks)
            .to eq(inner_call_value)
        end

        it "does not log any debug messages" do
          expect(Rails.logger).not_to have_received(:debug)
        end
      end
    end

    it "is thread safe" do
      thread = Thread.new do
        described_class.with true do
          inner = Thread.new do
            described_class.with false do
              described_class.active?
            end
          end

          [described_class.active?, inner.value]
        end
      end

      expect(thread.value)
        .to eql [true, false]
    end

    context "with an exception being raised within the block" do
      it "raises the exception but always resets the trigger_callbacks value" do
        expect { described_class.with(!trigger_callbacks_before) { raise ArgumentError } }
          .to raise_error ArgumentError

        expect(described_class.active?)
          .to eql trigger_callbacks_before
      end
    end
  end
end
