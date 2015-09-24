#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

require File.expand_path('../../../../../spec_helper', __FILE__)

describe 'api/experimental/projects/show.api.rabl', type: :view do
  let(:principals) { FactoryGirl.build_list(:principal, 3) }
  let(:types)     { FactoryGirl.build_list(:type,   2) }

  let(:project)   {
    project = FactoryGirl.build(:project,
                                possible_responsibles: principals,
                                possible_assignees:    principals,
                                types:                 types
                               )
  }

  before do
    params[:format] = 'json'

    assign(:project, project)
    render
  end

  subject { rendered }

  it { is_expected.to have_json_path('project') }
  it { is_expected.to have_json_path('project/name') }

  it { is_expected.to have_json_path('project/embedded/possible_responsibles') }
  it { is_expected.to have_json_path('project/embedded/possible_assignees')    }

  it { is_expected.to have_json_size(3).at_path('project/embedded/possible_responsibles') }
  it { is_expected.to have_json_size(3).at_path('project/embedded/possible_assignees') }
  it { is_expected.to have_json_size(2).at_path('project/embedded/types') }
end
