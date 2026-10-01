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

module WorkPackages::Dialogs
  class CreateDialogComponent < ApplicationComponent
    include ApplicationHelper
    include OpenProject::FormTagHelper
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers

    attr_reader :work_package, :project, :submit_url, :refresh_url, :keep_open_on_success

    def initialize(work_package:, project:, submit_url: nil, refresh_url: nil, keep_open_on_success: true)
      super

      @work_package = work_package
      @project = project
      @submit_url = submit_url
      @refresh_url = refresh_url
      @keep_open_on_success = keep_open_on_success
    end
  end
end
