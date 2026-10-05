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

RSpec.describe "Screens resolver fails open" do # rubocop:disable RSpec/DescribeClass
  let(:project) { create(:project) }
  let(:type) { create(:type) }

  before do
    ProjectType.create!(project:, type:)
    ::Screens::Resolver.reset_cache
  end

  after do
    ::Screens::Resolver.raise_on_error = false
    ::Screens::Resolver.reset_cache
  end

  it "logs, reports and returns a native layout on error" do
    allow(::Screens::Resolver).to receive(:project_assignment).and_raise(StandardError.new("boom"))
    expect(OpenProject.logger).to receive(:error).with(/\[screens\]/)
    expect(Rails.error).to receive(:report)

    result = ::Screens::Resolver.for(project, type, :create)
    expect(result).to be_native
    expect(result.reason).to eq("error")
  end

  it "re-raises when raise_on_error is enabled" do
    ::Screens::Resolver.raise_on_error = true
    allow(::Screens::Resolver).to receive(:project_assignment).and_raise(StandardError.new("boom"))

    expect { ::Screens::Resolver.for(project, type, :create) }.to raise_error(StandardError, "boom")
  end
end
