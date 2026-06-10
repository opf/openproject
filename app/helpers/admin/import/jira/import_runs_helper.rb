# frozen_string_literal: true

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

module Admin::Import::Jira::ImportRunsHelper
  def projects_label(count)
    I18n.t(:"admin.jira.run.wizard.parts.projects", count: count || 0)
  end

  def issues_label(count)
    return nil if count.nil?

    I18n.t(:"admin.jira.run.wizard.parts.issues", count:)
  end

  def work_packages_label(count)
    I18n.t(:"admin.jira.run.wizard.parts.work_packages", count: count || 0)
  end

  def statuses_label(count)
    return nil if count.nil?

    I18n.t(:"admin.jira.run.wizard.parts.statuses", count:)
  end

  def types_label(count)
    return nil if count.nil?

    I18n.t(:"admin.jira.run.wizard.parts.types", count:)
  end

  def users_label(count)
    I18n.t(:"admin.jira.run.wizard.parts.users", count: count || 0)
  end
end
