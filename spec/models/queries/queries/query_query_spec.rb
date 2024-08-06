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

RSpec.describe Queries::Queries::QueryQuery do
  let(:user) { build_stubbed(:user) }
  let(:instance) { described_class.new(user:) }
  let(:base_scope) { Query.visible(user).order(id: :desc) }

  context "without a filter" do
    describe "#results" do
      it "is the same as getting all visible queries" do
        expect(instance.results.to_sql).to eql base_scope.to_sql
      end
    end
  end

  context "with an updated_at filter" do
    before do
      instance.where("updated_at", "<>d", ["2018-03-22 20:00:00"])
    end

    describe "#results" do
      it "is the same as handwriting the query" do
        expected = base_scope.merge(Query.where("queries.updated_at >= '2018-03-22 20:00:00'"))

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end
  end

  context "with a project filter" do
    before do
      instance.where("project_id", "=", ["1", "2"])
    end

    describe "#results" do
      it "is the same as handwriting the query" do
        # apparently, strings are accepted to be compared to
        # integers in the postgresql
        expected = base_scope
                   .merge(Query.where("queries.project_id IN ('1','2')"))

        expect(instance.results.to_sql).to eql expected.to_sql
      end
    end

    describe "#valid?" do
      it "is true" do
        expect(instance).to be_valid
      end

      it "is invalid if the filter is invalid" do
        instance.where("name", "=", [""])
        expect(instance).to be_invalid
      end
    end
  end
end
