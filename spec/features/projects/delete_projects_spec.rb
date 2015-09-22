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
require 'features/projects/projects_page'

describe 'Delete project', type: :feature, js: true do
  let(:current_user) { FactoryGirl.create (:admin) }
  let(:project) { FactoryGirl.create(:project) }
  let(:projects_page) { ProjectsPage.new(project) }

  before do
    allow(User).to receive(:current).and_return current_user

    projects_page.visit_confirm_destroy
  end

  describe 'disable delete w/o confirm' do
    it { expect(page).to have_css('.danger-zone .button[disabled]') }
  end

  describe 'disable delete with wrong input' do
    let(:input) { find('.danger-zone input') }
    it do
      input.set 'Not the project name'
      expect(page).to have_css('.danger-zone .button[disabled]')
    end
  end

  describe 'enable delete with correct input' do
    let(:input) { find('.danger-zone input') }
    it do
      input.set project.name
      expect(page).to have_css('.danger-zone .button:not([disabled])')
    end
  end
end
