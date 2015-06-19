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

describe 'Delete project', type: :feature do
  let(:current_user) { FactoryGirl.create (:admin) }
  let(:project) { FactoryGirl.create(:project) }
  let(:projects_page) { ProjectsPage.new(project) }
  let(:delete_button) { find('input[type="submit"]') }

  before do
    allow(User).to receive(:current).and_return current_user

    projects_page.visit_confirm_destroy
  end

  it { expect(find('input#confirm')).not_to be_nil }

  describe 'click delete w/o confirm' do
    before { delete_button.click }

    it { expect(find('.error', text: I18n.t(:notice_project_not_deleted))).not_to be_nil }
  end

  describe 'click delete with confirm' do
    let(:confirm_checkbox) { find('input#confirm') }

    before do
      confirm_checkbox.set true

      delete_button.click
    end

    it { expect(find('h2', text: 'Projects')).not_to be_nil }
  end
end
