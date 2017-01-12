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

require "spec_helper"

describe "/time_entries", type: :feature do
  let(:user) { FactoryGirl.create :admin }

  describe "sorting time entries", js: true do
    let(:projects) { FactoryGirl.create_list :project, 3 }
    let(:comments) { ["TE 2", "TE 1", "TE 3"] }
    let(:hours) { [2, 5, 1] }

    let!(:time_entries) do
      comments.zip(projects).zip(hours).map do |comment_and_project, hours|
        comment, project = comment_and_project
        work_package = FactoryGirl.create :work_package, project: project

        FactoryGirl.create :time_entry,
                           comments: comment,
                           work_package: work_package,
                           project: project,
                           hours: hours
      end
    end

    def shown_comments
      page.all("td.comments").map(&:text)
    end

    def shown_hours
      page.all("td.hours").map(&:text).map(&:to_i)
    end

    def ajax_indicator_saveguard
      expect(page).to have_no_selector('#ajax-indicator')
    end

    before do
      login_as user
      visit time_entries_path
    end

    it "should allow sorting the time entries" do
      expect(page).to have_selector('td.comments', "TE 2")
      expect(page).to have_selector('td.comments', "TE 1")
      expect(page).to have_selector('td.comments', "TE 3")


      click_on "Comment"
      ajax_indicator_saveguard
      expect(shown_comments).to eq comments.sort

      click_on "Hours"
      ajax_indicator_saveguard
      expect(shown_hours).to eq hours.sort.reverse
    end
  end
end
