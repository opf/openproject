#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
      class AttachmentRepresenter < Roar::Decorator
        include Roar::JSON::HAL
        include Roar::Hypermedia
        include API::V3::Utilities::PathHelper

        self.as_strategy = API::Utilities::CamelCasingStrategy.new

        property :_type, exec_context: :decorator

        link :self do
          {
            href: api_v3_paths.attachment(represented.id),
            title: "#{represented.filename}"
          }
        end

        link :work_package do
          work_package = represented.container
          {
            href: api_v3_paths.work_package(work_package.id),
            title: "#{work_package.subject}"
          } unless work_package.nil?
        end

        link :author do
          author = represented.author
          {
            href: api_v3_paths.user(author.id),
            title: "#{author.name} - #{author.login}"
          } unless author.nil?
        end

        property :id, render_nil: true
        property :filename, as: :fileName, render_nil: true
        property :disk_filename, as: :diskFileName, render_nil: true
        property :description, render_nil: true
        property :file_size, getter: -> (*) { filesize }, render_nil: true
        property :content_type, render_nil: true
        property :digest, render_nil: true
        property :downloads, render_nil: true
        property :created_at, getter: -> (*) { created_on.utc.iso8601 }, render_nil: true

        def _type
          'Attachment'
        end
      end
    end
  end
end
