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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe CustomActions::Register do
  let(:described_class_double) { described_class.clone }
  let(:klass) { Class }
  let(:default_registry) do
    {
      actions:
      [
        CustomActions::Actions::AssignedTo,
        CustomActions::Actions::CustomField,
        CustomActions::Actions::Date,
        CustomActions::Actions::DoneRatio,
        CustomActions::Actions::DueDate,
        CustomActions::Actions::EstimatedHours,
        CustomActions::Actions::Notify,
        CustomActions::Actions::Project,
        CustomActions::Actions::Priority,
        CustomActions::Actions::Responsible,
        CustomActions::Actions::StartDate,
        CustomActions::Actions::Status,
        CustomActions::Actions::Type
      ],
      conditions:
      [
        CustomActions::Conditions::Project,
        CustomActions::Conditions::Role,
        CustomActions::Conditions::Status,
        CustomActions::Conditions::Type
      ]
    }
  end

  before do
    described_class_double.instance_variable_set(:@actions, default_registry[:actions])
    described_class_double.instance_variable_set(:@conditions, default_registry[:conditions])
  end

  shared_examples_for "registry class" do
    let(:registered_list) { described_class_double.send(kind) }

    describe ".add" do
      subject(:method_call) { described_class_double.add(kind.to_s.singularize.to_sym, klass) }

      context "when class is already registered" do
        let(:klass) { default_registry[kind].sample }

        it "raises an error" do
          expect { method_call }.to raise_error StandardError
        end
      end

      it "adds class to list" do
        method_call
        expect(registered_list).to include klass
      end
    end

    describe "accessor" do
      subject(:method_call) { described_class_double.send(kind) }

      it "returns correct classes" do
        expect(method_call).to match_array default_registry[kind]
      end
    end

    describe ".remove" do
      subject(:method_call) { described_class_double.remove(klass) }

      context "when class is absend" do
        let(:klass) { Class }

        it "raises an error" do
          expect { method_call }.to raise_error StandardError
        end
      end

      context "when class is present" do
        let(:klass) { default_registry[kind].sample }

        it "has class before removing" do
          expect(registered_list).to include klass
        end

        it "removes class from list" do
          method_call
          expect(registered_list).not_to include klass
        end
      end
    end
  end

  context "when condition is used" do
    let(:kind) { :conditions }

    it_behaves_like "registry class"
  end

  context "when action is used" do
    let(:kind) { :actions }

    it_behaves_like "registry class"
  end
end
