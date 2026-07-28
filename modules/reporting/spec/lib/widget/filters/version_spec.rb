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

require_relative "../../../spec_helper"

RSpec.describe Widget::Filters::Version do
  let(:admin) { create(:admin) }
  let(:project) { create(:project, name: "Demo project") }
  let(:version) { create(:version, project:, name: "2.0.0") }

  let(:filter) do
    CostQuery::Filter::VersionId.new.tap { |f| f.values = [version.id.to_s] }
  end
  let(:widget) { described_class.new(filter) }

  before { login_as(admin) }

  describe "#available_versions" do
    subject(:items) { widget.send(:available_versions) }

    it "offers every version with a project-qualified label the autocompleter can filter" do
      expect(items).to include(id: version.id, name: "Demo project - 2.0.0")
    end

    it "builds the items without a query per version" do
      other_project = create(:project)
      create(:version, project:)
      create(:version, project: other_project)
      widget

      expect { widget.send(:available_versions) }.to have_a_query_limit(2)
    end
  end

  describe "#selected_version_ids" do
    subject(:ids) { widget.send(:selected_version_ids) }

    it "maps the filter values to integer ids the autocompleter matches against its items" do
      expect(ids).to eq([version.id])
    end

    context "when a blank value slips in" do
      let(:filter) do
        CostQuery::Filter::VersionId.new.tap { |f| f.values = [version.id.to_s, ""] }
      end

      it "drops it instead of coercing it to a spurious id 0" do
        expect(ids).to eq([version.id])
      end
    end
  end
end
