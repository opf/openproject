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

RSpec.describe A11y::DemoSweep::LinkPolicy do
  subject(:policy) do
    described_class.new(origin: "http://example.test",
                        recognize: ->(path) { Rails.application.routes.recognize_path(path, method: :get) })
  end

  it "recognizes global, administration and project menu destinations" do
    %w[/ /admin /users /projects/demo-project /projects/demo-project/work_packages].each do |path|
      expect(policy.destination({ "href" => path }, from: "/")).to eq(path)
    end
  end

  it "matches work package details from a project-scoped work package index" do
    expect(policy.detail?("/work_packages/123", index: "/projects/demo-project/work_packages")).to be true
  end

  it "rejects actual GET action routes" do
    %w[/logout /work_packages/new /work_packages/123/copy /work_packages/export_dialog].each do |path|
      expect(policy.destination({ "href" => path }, from: "/")).to be_nil
    end
  end
end
