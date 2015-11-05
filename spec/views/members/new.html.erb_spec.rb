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

require 'spec_helper'

describe 'members/new', type: :view do
  let(:current_user) { FactoryGirl.build :admin }
  let(:project) { FactoryGirl.build :project }

  before do
    assign(:project, project)
    assign(:principals_available, [])

    allow(view).to receive(:current_user).and_return(current_user)
  end

  context 'with roles' do
    let(:role) { FactoryGirl.build :role }

    before do
      assign(:roles, [role])
      render
    end

    it 'should render the new member form' do
      expect(rendered).to have_content 'New member'
    end
  end

  context 'without roles' do
    before do
      assign(:roles, [])
      render
    end

    it 'should let the user know there are no roles defined' do
      expect(rendered).to have_content 'no roles defined'
    end
  end
end
