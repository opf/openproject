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
require 'features/support/toggable_fieldsets'
require 'features/work_packages/work_packages_page'

describe 'Work package calendar index', type: :feature do
  describe 'Toggable fieldset', js: true do
    include_context 'Toggable fieldset examples'

    let(:project) { FactoryGirl.create(:project) }
    let(:current_user) { FactoryGirl.create (:admin) }
    let(:work_packages_page) { WorkPackagesPage.new(project) }

    before do
      allow(User).to receive(:current).and_return current_user

      work_packages_page.visit_calendar
    end

    describe 'Filter fieldset', js: true do
      it_behaves_like 'toggable fieldset initially expanded' do
        let(:fieldset_name) { 'Filters' }
      end
    end
  end
end
