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

require "roar/decorator"
require "roar/json/hal"

module API
  module V3
    module Attachments
      class AttachmentParsingRepresenter < ::API::Decorators::Single
        nested :metadata do
          property :filename,
                   as: :fileName

          property :description,
                   getter: ->(*) {
                     ::API::Decorators::Formattable.new(description, plain: true)
                   },
                   setter: ->(fragment:, **) { self.description = fragment["raw"] },
                   render_nil: true

          property :content_type,
                   as: :contentType,
                   render_nil: false

          property :filesize,
                   as: :fileSize,
                   render_nil: false

          property :digest,
                   render_nil: false
        end

        property :file,
                 setter: ->(fragment:, represented:, doc:, **) {
                   filename = represented.filename || doc.dig("metadata", "fileName")
                   self.file = OpenProject::Files.build_uploaded_file fragment[:tempfile],
                                                                      fragment[:type],
                                                                      file_name: filename
                 }
      end
    end
  end
end
