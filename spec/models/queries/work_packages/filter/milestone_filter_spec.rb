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

RSpec.describe Queries::WorkPackages::Filter::MilestoneFilter do
  it_behaves_like "basic query filter" do
    let(:type) { :list }
    let(:class_key) { :is_milestone }
    let(:human_name) { "Is milestone" }

    describe "#available?" do
      context "within a project" do
        before do
          allow(project)
            .to receive_message_chain(:rolled_up_types, :exists?)
            .and_return true
        end

        it "is true" do
          expect(instance).to be_available
        end

        it "is false without a type" do
          allow(project)
            .to receive_message_chain(:rolled_up_types, :exists?)
            .and_return false

          expect(instance).not_to be_available
        end
      end

      context "without a project" do
        let(:project) { nil }

        before do
          allow(Type)
            .to receive_message_chain(:order, :exists?)
            .and_return true
        end

        it "is true" do
          expect(instance).to be_available
        end

        it "is false without a type" do
          allow(Type)
            .to receive_message_chain(:order, :exists?)
            .and_return false

          expect(instance).not_to be_available
        end
      end
    end
  end

  it_behaves_like "boolean query filter", scope: false do
    let(:model) { WorkPackage.unscoped }
    let(:attribute) { :id }

    # Which types count as milestones is the Type.milestone scope's business, as a variant
    # inherits the flag from its root; only the operator is asserted here.
    let(:milestone_types) { Type.milestone.select(:id).to_sql }

    describe "#scope" do
      context "for the true value" do
        let(:values) { [OpenProject::Database::DB_VALUE_TRUE] }

        context 'for "="' do
          let(:operator) { "=" }

          it "is the same as handwriting the query" do
            expect(instance.where).to eql "type_id IN (#{milestone_types})"
          end
        end

        context 'for "!"' do
          let(:operator) { "!" }

          it "is the same as handwriting the query" do
            expect(instance.where).to eql "type_id NOT IN (#{milestone_types})"
          end
        end
      end

      context "for the false value" do
        let(:values) { [OpenProject::Database::DB_VALUE_FALSE] }

        context 'for "="' do
          let(:operator) { "=" }

          it "is the same as handwriting the query" do
            expect(instance.where).to eql "type_id NOT IN (#{milestone_types})"
          end
        end

        context 'for "!"' do
          let(:operator) { "!" }

          it "is the same as handwriting the query" do
            expect(instance.where).to eql "type_id IN (#{milestone_types})"
          end
        end
      end
    end
  end

  describe "milestones of a type family", with_flag: { type_variants: true } do
    shared_let(:milestone_root) { create(:type, is_milestone: true) }
    shared_let(:variant) { create(:type, parent: milestone_root) }
    shared_let(:regular_type) { create(:type, is_milestone: false) }

    before do
      # A variant's own column is meaningless, so it must not decide the outcome.
      variant.update_column(:is_milestone, false)
    end

    it "counts a variant of a milestone type as a milestone" do
      expect(Type.milestone).to include(milestone_root, variant)
    end

    it "leaves types outside such a family out" do
      expect(Type.milestone).not_to include(regular_type)
    end
  end
end
