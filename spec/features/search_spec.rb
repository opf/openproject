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

describe 'Search', type: :feature do
  describe 'pagination' do
    let(:project) { FactoryGirl.create :project }
    let(:user) { FactoryGirl.create :admin }

    let!(:work_packages) do
      (1..23).map do |n|
        subject = "Subject No. #{n}"
        FactoryGirl.create :work_package, subject: subject, project: project, created_at: "2016-11-21 #{n}:00".to_datetime
      end
    end

    let(:query) { "Subject" }

    def expect_range(a, b)
      (a..b).each do |n|
        expect(page.body).to include("No. #{n}")
        expect(page.body).to have_selector("a[href*='#{work_package_path(work_packages[n-1].id)}']")
      end
    end

    context 'project search' do
      before do
        login_as user

        visit search_path(project, q: query)
      end
      it "works" do
        expect_range 14, 23

        click_on "Next", match: :first
        expect_range 4, 13
        expect(current_path).to match "/projects/#{project.identifier}/search"

        click_on "Previous", match: :first
        expect_range 14, 23
        expect(current_path).to match "/projects/#{project.identifier}/search"
      end
    end

    context 'global search' do
      before do
        login_as user

        visit "/search?q=#{query}"
      end

      it "works" do
        expect_range 14, 23

        click_on "Next", match: :first
        expect_range 4, 13

        click_on "Previous", match: :first
        expect_range 14, 23
      end
    end
  end
end
