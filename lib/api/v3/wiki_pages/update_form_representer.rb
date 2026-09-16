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
      class UpdateFormRepresenter < FormRepresenter
        include API::Decorators::UpdateForm
      end
    end
  end
end
