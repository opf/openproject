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

module Storages::Peripherals
  class ParseCreateParamsService < ::API::ParseResourceParamsService
    MAX_ELEMENTS = 20

    attr_reader :request_body

    private

    def parse_attributes(request_body)
      @request_body = request_body
      assert_valid_elements

      elements.map do |element|
        super(element)
      end
    end

    def elements
      @elements ||= request_body.dig("_embedded", "elements")
    end

    def assert_valid_elements
      assert_elements_is_present
      assert_elements_is_an_array
      assert_elements_does_not_exceed_maximum
    end

    def assert_elements_is_present
      return if elements.present?

      raise API::Errors::PropertyMissingError.new("_embedded/elements")
    end

    def assert_elements_is_an_array
      return if elements.is_a?(Array)

      raise API::Errors::PropertyFormatError.new("_embedded/elements", "Array", elements.class.name)
    end

    def assert_elements_does_not_exceed_maximum
      return if elements.size <= MAX_ELEMENTS

      raise API::Errors::Validation.new("_embedded/elements",
                                        I18n.t("api_v3.errors.too_many_elements_created_at_once",
                                               max: MAX_ELEMENTS, actual: elements.size))
    end
  end
end
