#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module Attachments
      class AttachmentRepresenter < ::API::Decorators::Single

        self_link title_getter: -> (*) { represented.filename }

        linked_property :author,
                        path: :user

        # implementation is currently work_package specific
        linked_property :container,
                        path: :work_package,
                        title_getter: -> (*) { represented.container.subject }

        link :downloadLocation do
          {
            href: api_v3_paths.attachment_download(represented.id)
          }
        end

        property :id
        property :file_name,
                 getter: -> (*) { filename }
        property :file_size,
                 getter: -> (*) { filesize }
        property :description,
                 getter: -> (*) {
                   ::API::Decorators::Formattable.new(description, format: 'plain')
                 },
                 render_nil: true
        property :content_type
        property :digest,
                 getter: -> (*) {
                   ::API::Decorators::Digest.new(digest, algorithm: 'md5')
                 },
                 render_nil: true
        property :created_on,
                 as: 'createdAt',
                 exec_context: :decorator,
                 getter: -> (*) { datetime_formatter.format_datetime(represented.created_on) }

        def _type
          'Attachment'
        end
      end
    end
  end
end
