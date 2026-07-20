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
  # Switches one configuration aspect of a type to Independent by severing its
  # link. When a source is given, its resolved configuration is adopted onto the
  # type once before the link is removed, so the type keeps what it was showing.
  #
  # Adoption reuses the aspect's CopyConfiguration service and the result is
  # aggregated with the severing, so a failed copy leaves the link untouched.
  class SwitchToIndependentModeService
    def initialize(type:, aspect:, user:)
      @type = type
      @aspect = aspect
      @user = user
    end

    def call(source: nil)
      result = adopt_configuration_from(source)
      result.merge!(sever_link) if result.success?

      result
    end

    private

    attr_reader :type, :aspect, :user

    def adopt_configuration_from(source)
      return ServiceResult.success(result: type) unless adopt?(source)

      CopyConfiguration.service_for(aspect).new(type:, user:).call(source:)
    end

    def adopt?(source)
      source.present? && source != type && CopyConfiguration.supported?(aspect)
    end

    def sever_link
      type.configuration_links.where(aspect:).destroy_all
      ServiceResult.success(result: type)
    end
  end
end
