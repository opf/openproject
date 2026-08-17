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

module Repositories
  class DestroyDialogComponent < ApplicationComponent
    include ApplicationHelper
    include OpTurbo::Streamable

    def initialize(project:, repository:)
      super

      @project = project
      @repository = repository
    end

    private

    def id = "destroy-repository-dialog"

    def repository_label
      "#{@repository.repository_type} - #{I18n.t(:project_module_repository)}"
    end

    def dialog_title
      if @repository.managed?
        I18n.t("repositories.destroy_dialog.title")
      else
        I18n.t("repositories.destroy_dialog.title_not_managed")
      end
    end

    def dialog_heading
      if @repository.managed?
        I18n.t("repositories.destroy_dialog.heading", repository_type: repository_label)
      else
        I18n.t("repositories.destroy_dialog.heading_not_managed", repository_type: repository_label)
      end
    end
  end
end
