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

    describe "#scope" do
      context "for the true value" do
        let(:values) { [OpenProject::Database::DB_VALUE_TRUE] }

        context 'for "="' do
          let(:operator) { "=" }

          it "is the same as handwriting the query" do
            expected = 'type_id IN (SELECT "types"."id" FROM "types" WHERE "types"."is_milestone" = TRUE ORDER BY position ASC)'

            expect(instance.where).to eql expected
          end
        end

        context 'for "!"' do
          let(:operator) { "!" }

          it "is the same as handwriting the query" do
            expected = 'type_id NOT IN (SELECT "types"."id" FROM "types" WHERE "types"."is_milestone" = TRUE ORDER BY position ASC)'

            expect(instance.where).to eql expected
          end
        end
      end

      context "for the false value" do
        let(:values) { [OpenProject::Database::DB_VALUE_FALSE] }

        context 'for "="' do
          let(:operator) { "=" }

          it "is the same as handwriting the query" do
            expected = 'type_id NOT IN (SELECT "types"."id" FROM "types" WHERE "types"."is_milestone" = TRUE ORDER BY position ASC)'

            expect(instance.where).to eql expected
          end
        end

        context 'for "!"' do
          let(:operator) { "!" }

          it "is the same as handwriting the query" do
            expected = 'type_id IN (SELECT "types"."id" FROM "types" WHERE "types"."is_milestone" = TRUE ORDER BY position ASC)'

            expect(instance.where).to eql expected
          end
        end
      end
    end
  end
end
