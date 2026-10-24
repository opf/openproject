# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Queries
  module Wikis
    module WikiPages
      module Filter
        class UpdatedAtFilter < Filters::Base
          self.model = ::WikiPage

          def type = :datetime_past

          def human_name = ::WikiPage.human_attribute_name(:updated_at)
        end
      end
    end
  end
end
