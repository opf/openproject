# frozen_string_literal: true

# -- copyright
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
# ++

class WorkPackages::IndexPageHeaderComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers
  include ApplicationHelper

  def initialize(query: nil, project: nil)
    super

    @query = query
    @project = project
  end

  def breadcrumb_items
    items = [{ href: @project ? project_work_packages_path : work_packages_path, text: t(:label_work_package_plural) },
             title]

    if @project
      items.prepend({ href: project_overview_path(@project.id), text: @project.name })
    end

    items
  end

  def title
    @query&.name ? @query.name : t(:label_work_package_plural)
  end

  def can_rename?
    # TODO
    true
  end

  def can_save?
    # TODO
    true
  end

  def can_save_as?
    # TODO
    true
  end

  def can_delete?
    # TODO
    true
  end
end
