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

describe 'api/v2/project_associations/index.api.rabl', type: :view do
  before do
    params[:format] = 'json'
  end

  describe 'with no project_associations available' do
    it 'renders an empty project_associations document' do
      assign(:project_associations, [])
      render

      expect(rendered).to have_json_size(0).at_path('project_associations')
    end
  end

  describe 'with 3 project_associations available' do
    let(:project_associations) do
      [
        FactoryGirl.build(:project_association),
        FactoryGirl.build(:project_association),
        FactoryGirl.build(:project_association)
      ]
    end

    before do
      assign(:project_associations, project_associations)
      render
    end

    it 'renders a project_associations document with the size 3 of array' do
      expect(rendered).to have_json_size(3).at_path('project_associations')
    end
  end
end
