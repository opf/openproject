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

module WorkPackageTypes
  # Sets one configuration aspect of a type to Linked (a chosen global source) or
  # Independent. The source-graph invariants (present, global, not-self) are the
  # link record's own validations; this service maps the UI mode onto them.
  class SetConfigurationLinkService
    def initialize(type:, aspect:)
      @type = type
      @aspect = aspect
    end

    def call(mode:, source_id: nil)
      source = Type.global.find_by(id: source_id)

      case mode.to_s
      when "independent"
        @type.make_independent!(@aspect, source:)
        ServiceResult.success(result: @type)
      when "linked"
        link_to(source)
      else
        ServiceResult.failure(result: @type)
      end
    end

    private

    def link_to(source)
      link = @type.configuration_links.find_or_initialize_by(aspect: @aspect)
      link.source = source

      if link.save
        ServiceResult.success(result: @type)
      else
        ServiceResult.failure(result: @type, errors: link.errors)
      end
    end
  end
end
