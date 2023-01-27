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

require File.expand_path("#{File.dirname(__FILE__)}/../../spec_helper.rb")

describe OpenProject::JournalFormatter::Parent do
  let(:instance) { described_class.new(build(:journal)) }
  let(:project1) { create(:project, id: 100) }
  let(:project2) { create(:project, id: 42) }

  it "renders correctly when setting new parent" do
    html = instance.render("parent", [nil, project1.id], html: true)
    expect(html).to eq("<strong>Parent</strong> set to <i>#{project1.name}</i>")

    html = instance.render("parent", [nil, project1.id], html: false)
    expect(html).to eq("Parent set to #{project1.name}")
  end

  it "renders correctly when changing parents" do
    html = instance.render("parent", [project1.id, project2.id], html: true)
    expect(html).to eq("<strong>Parent</strong> changed from <i>#{project1.name}</i> to <i>#{project2.name}</i>")

    html = instance.render("parent", [project1.id, project2.id], html: false)
    expect(html).to eq("Parent changed from #{project1.name} to #{project2.name}")
  end
end
