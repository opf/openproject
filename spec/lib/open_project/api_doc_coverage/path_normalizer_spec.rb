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
# frozen_string_literal: true

require "spec_helper"
require "open_project/api_doc_coverage/path_normalizer"

RSpec.describe OpenProject::ApiDocCoverage::PathNormalizer do
  describe ".canonical_path" do
    it "maps a Grape member route to the /api/v3 OpenAPI form" do
      expect(described_class.canonical_path("/:version/work_packages/:id(.:format)"))
        .to eq("/api/v3/work_packages/{id}")
    end

    it "maps a collection route" do
      expect(described_class.canonical_path("/:version/work_packages(.:format)"))
        .to eq("/api/v3/work_packages")
    end

    it "handles nested and multi-param paths" do
      expect(described_class.canonical_path("/:version/projects/:project_id/versions/:id(.:format)"))
        .to eq("/api/v3/projects/{project_id}/versions/{id}")
    end

    it "handles the bare version root" do
      expect(described_class.canonical_path("/:version(.:format)")).to eq("/api/v3")
    end

    it "maps a splat param (used where a segment may contain slashes) like a regular param" do
      expect(described_class.canonical_path("/:version/actions/*id(.:format)"))
        .to eq("/api/v3/actions/{id}")
    end
  end

  describe ".module_name" do
    it "returns the first segment after /api/v3" do
      expect(described_class.module_name("/api/v3/work_packages/{id}")).to eq("work_packages")
    end

    it "returns (root) for the bare version root" do
      expect(described_class.module_name("/api/v3")).to eq("(root)")
    end
  end
end
