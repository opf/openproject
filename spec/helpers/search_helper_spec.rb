#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'search/index' do
  let(:project) { FactoryGirl.create(:project) }
  let(:scope) { "foobar" }

  before do
    helper.stub(:params).and_return({
      :q => "foobar",
      :all_words => "1",
      :scope => scope
    })
    assign(:project, project)
  end

  it 'renders correct result-by-type links' do
    results_by_type = {"work_packages"=>1, "wiki_pages"=>1}
    response = helper.render_results_by_type(results_by_type)

    expect(response).to have_selector("a", :count => results_by_type.size)
    expect(response).to include("/projects/#{project.identifier}/search")
    expect(response).to include("scope=#{scope}")
  end
end
