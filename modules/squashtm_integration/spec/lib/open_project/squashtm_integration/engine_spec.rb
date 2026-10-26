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

require "spec_helper"

RSpec.describe OpenProject::SquashTMIntegration::Engine do
  it "registers the plugin" do
    expect(Redmine::Plugin.registered_plugins).to include(:openproject_squashtm_integration)
  end

  it "is bundled with OpenProject" do
    expect(Redmine::Plugin.find(:openproject_squashtm_integration)).to be_bundled
  end

  it "treats SquashTM as an acronym" do
    expect("squashtm_integration".camelize).to eq("SquashTMIntegration")
    expect("SquashTMIntegration".underscore).to eq("squashtm_integration")
  end
end
