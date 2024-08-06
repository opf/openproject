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
require_relative "shared_query_select_specs"

RSpec.describe Queries::WorkPackages::Selects::RelationToTypeSelect do
  let(:project) { build_stubbed(:project) }
  let(:type) { build_stubbed(:type) }
  let(:instance) { described_class.new(type) }
  let(:enterprise_token_allows) { true }

  it_behaves_like "query column"

  describe "instances" do
    before do
      allow(EnterpriseToken)
        .to receive(:allows_to?)
        .with(:work_package_query_relation_columns)
        .and_return(enterprise_token_allows)
    end

    context "within project" do
      before do
        allow(project)
          .to receive(:types)
          .and_return([type])
      end

      context "with a valid enterprise token" do
        it "contains the type columns" do
          expect(described_class.instances(project).length)
            .to eq 1

          expect(described_class.instances(project)[0].type)
            .to eq type
        end
      end

      context "without a valid enterprise token" do
        let(:enterprise_token_allows) { false }

        it "is empty" do
          expect(described_class.instances)
            .to be_empty
        end
      end
    end

    context "global" do
      before do
        allow(Type)
          .to receive(:all)
          .and_return([type])
      end

      context "with a valid enterprise token" do
        it "contains the type columns" do
          expect(described_class.instances.length)
            .to eq 1

          expect(described_class.instances[0].type)
            .to eq type
        end
      end

      context "without a valid enterprise token" do
        let(:enterprise_token_allows) { false }

        it "is empty" do
          expect(described_class.instances)
            .to be_empty
        end
      end
    end
  end
end
