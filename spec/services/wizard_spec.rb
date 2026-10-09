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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Wizard do
  subject(:wizard) { wizard_class.new(model:) }

  let(:wizard_class) do
    Class.new(described_class) do
      step :a, completed_if: ->(i) { i > 0 }
      step :b, completed_if: :greater_five
      step :c, completed_if: ->(i) { i > 10 }

      def greater_five(number)
        number > 5
      end
    end
  end
  let(:model) { 5 }

  it "lists all steps" do
    expect(wizard.steps).to eq(%i[a b c])
  end

  it "lists all completed steps" do
    expect(wizard.completed_steps).to eq(%i[a])
  end

  it "lists all pending steps" do
    expect(wizard.pending_steps).to eq(%i[b c])
  end

  describe "conditional steps" do
    let(:wizard_class) do
      Class.new(described_class) do
        step :a, completed_if: ->(i) { i > 0 }, if: ->(i) { i.even? }
        step :b, completed_if: ->(i) { i > 4 }, if: :odd
        step :c, completed_if: ->(i) { i > 10 }, if: :even
        step :d, completed_if: ->(i) { i > 20 }, if: ->(i) { i.odd? }
        step :e, completed_if: ->(i) { i > 30 }

        def odd(number)
          number.odd?
        end

        def even(number)
          number.even?
        end
      end
    end

    it "lists relevant steps" do
      expect(wizard.steps).to eq(%i[b d e])
    end

    it "lists relevant completed steps" do
      expect(wizard.completed_steps).to eq(%i[b])
    end

    it "lists relevant pending steps" do
      expect(wizard.pending_steps).to eq(%i[d e])
    end

    it "determines next steps", :aggregate_failures do
      expect(wizard.step_after(:a)).to be_nil
      expect(wizard.step_after(:b)).to eq(:d)
      expect(wizard.step_after(:c)).to be_nil
      expect(wizard.step_after(:d)).to eq(:e)
      expect(wizard.step_after(:e)).to be_nil
      expect(wizard.step_after(:x)).to be_nil
    end

    context "when model matches alternative conditions" do
      let(:model) { 6 }

      it "lists relevant steps" do
        expect(wizard.steps).to eq(%i[a c e])
      end

      it "lists relevant completed steps" do
        expect(wizard.completed_steps).to eq(%i[a])
      end

      it "lists relevant pending steps" do
        expect(wizard.pending_steps).to eq(%i[c e])
      end

      it "determines next steps", :aggregate_failures do
        expect(wizard.step_after(:a)).to eq(:c)
        expect(wizard.step_after(:b)).to be_nil
        expect(wizard.step_after(:c)).to eq(:e)
        expect(wizard.step_after(:d)).to be_nil
        expect(wizard.step_after(:e)).to be_nil
        expect(wizard.step_after(:x)).to be_nil
      end
    end
  end

  describe "#prepare_next_step" do
    subject(:call) { wizard_class.new(model:).prepare_next_step }

    let(:wizard_class) do
      do_call = call_double # binding to local variable, so that it can be passed into class block
      Class.new(described_class) do
        def self.dont_call(step_name)
          ->(_) { raise "Step #{step_name} should not have been prepared" }
        end

        step :a, completed_if: ->(i) { i > 0 }, preparation: dont_call(:a)
        step :b, completed_if: ->(i) { i > 10 }, if: ->(i) { i.even? }, preparation: dont_call(:b)
        step :c, completed_if: ->(i) { i > 10 }, if: ->(i) { i.odd? }, preparation: do_call
        step :d, completed_if: ->(i) { i > 20 }, if: ->(i) { i.odd? }, preparation: dont_call(:d)
      end
    end
    let(:call_double) { instance_double(Proc, call: nil) }

    it { is_expected.to eq(:c) }

    it "calls the prepare hook for step c" do
      call
      expect(call_double).to have_received(:call).with(model)
    end

    context "when all steps are completed" do
      let(:model) { 100 }

      it { is_expected.to be_nil }

      it "does not prepare anything" do
        call
        expect(call_double).not_to have_received(:call)
      end
    end
  end

  describe "#section_name" do
    let(:wizard_class) do
      Class.new(described_class) do
        step :a, completed_if: ->(i) { i > 0 }
        step :b, completed_if: ->(i) { i > 10 }, section: :c
      end
    end

    it "defaults to the step name" do
      expect(wizard.section_name(:a)).to eq(:a)
    end

    it "uses the name passed by section parameter if present" do
      expect(wizard.section_name(:b)).to eq(:c)
    end
  end
end
