#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'search/index', type: :view do
  let(:project)      { FactoryGirl.create :project }
  let(:user)         { FactoryGirl.create :admin, member_in_project: project }
  let(:work_package) { FactoryGirl.create :work_package, project: project }

  before do
    assign :project, project
    assign :object_types, ['work_packages']
    assign :scope, ['work_packages', 'changesets']
    assign :results, [work_package]
    assign :results_by_type, 'work_packages' => 1
    assign :question, 'foo'
    assign :tokens, ['bar']
  end

  it 'selects the current project' do
    render

    # the current project should be selected as the scope
    expect(rendered).to have_selector('option[selected]', text: project.name)

    # The grouped result link should retain the scope
    expect(rendered).to have_xpath("//a[contains(@href,'current_project')]", text: /work packages.*/i)
  end
end
