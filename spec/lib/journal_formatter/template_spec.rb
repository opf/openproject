#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

describe OpenProject::JournalFormatter::Template do
  let(:instance) { described_class.new(build(:journal)) }

  it "renders correctly when un-marked as template" do
    html = instance.render("templated", [false, true], html: true)
    expect(html).to eq("<strong>Template:</strong> Project un-marked as template")

    html = instance.render("templated", [false, true], html: false)
    expect(html).to eq("Template: Project un-marked as template")
  end

  it "renders correctly when marked as template" do
    html = instance.render("templated", [true, false], html: true)
    expect(html).to eq("<strong>Template:</strong> Project marked as template")

    html = instance.render("templated", [true, false], html: false)
    expect(html).to eq("Template: Project marked as template")
  end
end
