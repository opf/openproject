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

module AI
  # Demo only (AI-126): renders the markdown the result popover receives. The API v3 render
  # endpoints were removed from dev (OP-19480), so nothing else can turn the streamed markdown
  # into formatted text for a client.
  class TextTransformPreviewsController < ApplicationController
    include OpenProject::TextFormatting

    no_authorization_required! :create

    layout false

    def create
      return head(:unauthorized) unless current_user.logged?

      render html: format_text(params[:markdown].to_s, object: work_package)
    end

    private

    def work_package
      id = params[:work_package_id].to_i
      WorkPackage.visible.find_by(id:) if id.positive?
    end
  end
end
