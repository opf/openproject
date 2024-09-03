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

RSpec.describe Queries::Relations::RelationQuery do
  let(:instance) { described_class.new }
  let(:base_scope) { Relation.order(id: :desc) }

  context "without a filter" do
    describe "#results" do
      it "is the same as getting all the relations" do
        expect(instance.results.to_sql).to eql base_scope.visible.to_sql
      end
    end

    describe "#valid?" do
      it "is true" do
        expect(instance).to be_valid
      end
    end
  end

  context "with a type filter" do
    before do
      instance.where("type", "=", ["follows", "blocks"])
    end

    describe "#results" do
      it "is the same as handwriting the query" do
        expected = base_scope
                   .merge(Relation
                          .where("relations.relation_type IN ('follows','blocks')"))
                   .visible

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end

    describe "#valid?" do
      it "is true" do
        expect(instance).to be_valid
      end

      it "is invalid if the filter is invalid" do
        instance.where("type", "=", [""])

        expect(instance).to be_invalid
      end
    end
  end

  context "with a from filter" do
    let(:current_user) { build_stubbed(:user) }

    before do
      login_as(current_user)
      instance.where("from_id", "=", ["1"])
    end

    describe "#results" do
      it "is the same as handwriting the query (with visibility checked within the filter query)" do
        visible_sql = WorkPackage.visible(current_user).select(:id).to_sql

        expected = base_scope
                   .merge(Relation
                          .where("from_id IN ('1') AND to_id IN (#{visible_sql})"))

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end
  end

  context "with an order by id asc" do
    describe "#results" do
      it "returns all visible relations ordered by id asc" do
        expect(instance.order(id: :asc).results.to_sql)
          .to eql base_scope.visible.except(:order).order(id: :asc).to_sql
      end
    end
  end
end
