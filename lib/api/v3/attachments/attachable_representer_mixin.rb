#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Attachments
      module AttachableRepresenterMixin
        extend ActiveSupport::Concern

        cattr_accessor :attachments_by_link

        included do
          link :attachments do
            {
              href: attachments_by_resource
            }
          end

          link :addAttachment,
               cache_if: -> do
                 represented.attachments_addable?(current_user)
               end do
            {
              href: attachments_by_resource,
              method: :post
            }
          end

          property :attachments,
                   embedded: true,
                   exec_context: :decorator,
                   if: ->(*) { embed_links },
                   uncacheable: true

          def attachments
            ::API::V3::Attachments::AttachmentCollectionRepresenter.new(attachment_set,
                                                                        attachments_by_resource,
                                                                        current_user: current_user)
          end

          def attachments_by_resource
            path = "attachments_by_#{_type.singularize.underscore}"

            api_v3_paths.send(path, represented.id)
          end

          def attachment_set
            # Depending on the way attachments are handled we have three different cases:
            # * The attachments are replaced completely (but are not yet persisted)
            # * Additional attachments will be added to the container (but are not yet persisted)
            # * We only have the already persisted attachments
            #
            # The first two cases can happen e.g., when new and coming back from backend with an error.
            if represented.attachments_replacements
              represented.attachments_replacements
            elsif represented.attachments_claimed
              represented.attachments.concat(represented.attachments_claimed)
            else
              represented.attachments
            end
          end
        end
      end
    end
  end
end
