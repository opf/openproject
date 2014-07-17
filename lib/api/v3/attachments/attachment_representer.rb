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
require 'roar/representer/json/hal'

module API
  module V3
    module Attachments
      class AttachmentRepresenter < Roar::Decorator
        include Roar::Representer::JSON::HAL
        include Roar::Representer::Feature::Hypermedia
        include OpenProject::StaticRouting::UrlHelpers

        self.as_strategy = API::Utilities::CamelCasingStrategy.new

        property :_type, exec_context: :decorator

        link :self do
          { href: "#{root_url}api/v3/attachments/#{represented.model.id}", title: "#{represented.model.filename}" }
        end

        link :work_package do
          work_package = represented.model.container
          { href: "#{root_url}api/v3/work_packages/#{work_package.id}", title: "#{work_package.subject}" } unless work_package.nil?
        end

        link :author do
          author = represented.model.author
          { href: "#{root_url}api/v3/users/#{author.id}", title: "#{author.name} - #{author.login}" } unless author.nil?
        end

        property :id, getter: -> (*) { model.id }, render_nil: true
        property :filename, as: :fileName, render_nil: true
        property :disk_filename, as: :diskFileName, render_nil: true
        property :description, render_nil: true
        property :file_size, getter: -> (*) { model.filesize }, render_nil: true
        property :content_type, getter: -> (*) { model.content_type }, render_nil: true
        property :digest, render_nil: true
        property :downloads, getter: -> (*) { model.downloads }, render_nil: true
        property :created_at, getter: -> (*) { model.created_on.utc.iso8601 }, render_nil: true

        def _type
          'Attachment'
        end
      end
    end
  end
end
