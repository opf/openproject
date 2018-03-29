#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'my/page', type: :view do
  let(:project)    { FactoryGirl.create :valid_project }
  let(:user)       { FactoryGirl.create :admin, member_in_project: project }
  let(:issue)      { FactoryGirl.create :work_package, project: project, author: user }
  let(:time_entry) {
    FactoryGirl.create :time_entry,
                       project: project,
                       user: user,
                       work_package: issue,
                       hours: 1
  }

  describe 'timelog block' do
    before do
      assign(:user, user)
      time_entry.spent_on = Date.today
      time_entry.save!
    end

    it 'renders the timelog block' do
      assign :blocks,  'top' => ['timelog'], 'left' => [], 'right' => []

      render

      expect(rendered).to have_selector("tr.time-entry td.subject a[href='#{work_package_path(issue)}']",
                                        text: "#{issue.type.name} ##{issue.id}")
    end
  end
end
