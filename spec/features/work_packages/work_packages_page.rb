#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

class WorkPackagesPage
  include Rails.application.routes.url_helpers
  include Capybara::DSL
  include Capybara::RSpecMatchers
  include RSpec::Matchers

  def initialize(project = nil)
    @project = project
  end

  def visit_index(work_package = nil)
    visit index_path(work_package)

    ensure_index_page_loaded
  end

  def visit_new
    visit new_project_work_packages_path(@project)
  end

  def visit_show(id)
    visit work_package_path(id)
  end

  def visit_edit(id)
    visit edit_work_package_path(id)
  end

  def visit_calendar
    visit index_path + "/calendar"
  end

  def open_settings!
    click_on "work-packages-settings-button"
  end

  def click_work_packages_menu_item
    find("#main-menu .work-packages").click
  end

  def click_toolbar_button(button)
    close_toasters
    find(".toolbar-container", wait: 5).click_button button
  end

  def close_toasters
    page.all(:css, ".op-toast--close").each(&:click)
  end

  def select_query(query)
    visit query_path(query)

    ensure_index_page_loaded
  end

  def find_subject_field(text = nil)
    if text
      find_by_id("inplace-edit--write-value--subject", text:)
    else
      find_by_id("inplace-edit--write-value--subject")
    end
  end

  def ensure_loaded
    ensure_index_page_loaded
  end

  private

  def index_path(work_package = nil)
    path = @project ? project_work_packages_path(@project) : work_packages_path
    path += "/details/#{work_package.id}/overview" if work_package
    path
  end

  def query_path(query)
    "#{index_path}?query_id=#{query.id}"
  end

  def ensure_index_page_loaded
    if Capybara.current_driver == Capybara.javascript_driver
      expect(page).to have_css(".work-packages--filters-optional-container.-loaded", visible: :all, wait: 20)
    end
  end
end
