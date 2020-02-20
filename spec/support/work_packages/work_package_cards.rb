#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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

class WorkPackageCards
  include Capybara::DSL
  include RSpec::Matchers
  attr_reader :project

  def initialize(project = nil)
    @project = project
  end

  def open_full_screen_by_doubleclick(work_package)
    loading_indicator_saveguard
    page.driver.browser.action.double_click(card(work_package).native).perform

    Pages::FullWorkPackage.new(work_package, project)
  end

  def select_work_package(work_package)
    card(work_package).click
  end

  def card(work_package)
    page.find(".wp-card-#{work_package.id}")
  end
end
