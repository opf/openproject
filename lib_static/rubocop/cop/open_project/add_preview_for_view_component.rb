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

module RuboCop::Cop::OpenProject
  class AddPreviewForViewComponent < RuboCop::Cop::Base
    COMPONENT_PATH = "/app/components/"
    PREVIEW_PATH = "/lookbook/previews/"

    def on_class(node)
      path = node.loc.expression.source_buffer.name
      return unless path.include?(COMPONENT_PATH) && path.end_with?(".rb")

      preview_path = path.sub(COMPONENT_PATH, PREVIEW_PATH).sub(".rb", "_preview.rb")

      unless File.exist?(preview_path)
        message = "Missing Lookbook preview for #{path}. Expected preview to exist at #{preview_path}."
        add_offense(node.loc.name, message:)
      end
    end
  end
end
