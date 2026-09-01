#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#++

module API
  module V3
    module WikiPages
      class WikiPagePayloadRepresenter < WikiPageRepresenter
        include ::API::Utilities::PayloadRepresenter
        include ::API::V3::Attachments::AttachablePayloadRepresenterMixin

        cached_representer disabled: true

        def writable_attributes
          attrs = super + %w[parent project]
          attrs += %w[redirectExistingLinks] if represented.respond_to?(:redirect_existing_links=)
          attrs
        end

        property :redirect_existing_links,
                 as: :redirectExistingLinks,
                 exec_context: :decorator,
                 render_nil: false,
                 getter: ->(*) {},
                 setter: ->(fragment:, **) {
                   represented.redirect_existing_links = fragment
                 }
      end
    end
  end
end
