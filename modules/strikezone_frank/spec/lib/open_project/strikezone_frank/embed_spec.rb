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

RSpec.describe OpenProject::StrikezoneFrank::Embed do
  describe ".origin" do
    it "defaults to the local Frank frontend" do
      expect(described_class.origin).to eq("http://localhost:3001")
    end
  end

  describe ".url" do
    it "loads the Frank PM embed without inventing a project" do
      expect(described_class.url).to eq("http://localhost:3001/embed/frank-pm")
    end

    it "encodes project context on the embed URL" do
      project = instance_double(Project, id: 42, name: "Acme & Co")
      uri = Addressable::URI.parse(described_class.url(project:))

      expect(uri.path).to eq("/embed/frank-pm")
      expect(uri.query_values).to eq(
        "projectId" => "42",
        "projectName" => "Acme & Co"
      )
    end
  end

  describe ".host_context" do
    it "builds the existing host-context payload" do
      project = instance_double(Project, id: 42, name: "Acme & Co")

      expect(described_class.host_context(project:)).to eq(
        source: "openproject-frank",
        type: "host-context",
        projectId: "42",
        projectName: "Acme & Co"
      )
    end

    it "omits empty project fields" do
      expect(described_class.host_context).to eq(
        source: "openproject-frank",
        type: "host-context"
      )
    end
  end
end
