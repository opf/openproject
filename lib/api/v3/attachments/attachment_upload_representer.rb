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
      class AttachmentUploadRepresenter < ::API::Decorators::Single
        include API::Decorators::DateProperty
        include API::Decorators::FormattableProperty
        include API::Decorators::LinkedResource

        self_link title_getter: ->(*) { represented.filename }

        associated_resource :author,
                            v3_path: :user,
                            representer: ::API::V3::Users::UserRepresenter

        def self.associated_container_getter
          ->(*) do
            next unless embed_links && container_representer

            container_representer
              .create(represented.container, current_user:)
          end
        end

        def self.associated_container_link
          ->(*) do
            return nil unless v3_container_name == "nil_class" || api_v3_paths.respond_to?(v3_container_name)

            ::API::Decorators::LinkObject
              .new(represented,
                   path: v3_container_name,
                   property_name: :container,
                   title_attribute: container_title_attribute)
              .to_hash
          end
        end

        attr_reader :form_url, :form_fields, :attachment

        def initialize(attachment, current_user:, embed_links: false)
          super

          fog_hash = DirectFogUploader.direct_fog_hash(attachment:)

          @form_url = fog_hash[:uri]
          @form_fields = fog_hash.except :uri
          @attachment = attachment
        end

        associated_resource :container,
                            getter: associated_container_getter,
                            link: associated_container_link

        link :addAttachment do
          {
            href: form_url,
            method: :post,
            form_fields:
          }
        end

        link :delete do
          {
            href: api_v3_paths.attachment_upload(represented.id),
            method: :delete
          }
        end

        link :staticDownloadLocation do
          {
            href: api_v3_paths.attachment_content(attachment.id)
          }
        end

        link :downloadLocation do
          location = if attachment.external_storage?
                       attachment.external_url
                     else
                       api_v3_paths.attachment_content(attachment.id)
                     end
          {
            href: location
          }
        end

        link :completeUpload do
          {
            href: api_v3_paths.attachment_uploaded(attachment.id)
          }
        end

        property :id
        property :file_name,
                 getter: ->(*) { filename }

        formattable_property :description,
                             plain: true

        date_time_property :created_at

        def _type
          "AttachmentUpload"
        end

        def container_representer
          name = v3_container_name.camelcase

          "::API::V3::#{name.pluralize}::#{name}Representer".constantize
        rescue NameError
          nil
        end

        def v3_container_name
          ::API::Utilities::PropertyNameConverter.from_ar_name(represented.container.class.name.underscore).underscore
        end

        def container_title_attribute
          represented.container.respond_to?(:subject) ? :subject : :title
        end
      end
    end
  end
end
