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

module OpenProject
  class CustomFieldFormatDependent
    CONFIG = {
      allowNonOpenVersions: [:only, %w[version]],
      defaultBool: [:only, %w[bool]],
      defaultLongText: [:only, %w[text]],
      defaultText: [:except, %w[list bool date text user version]],
      length: [:except, %w[list bool date user version link]],
      multiSelect: [:only, %w[list user version]],
      possibleValues: [:only, %w[list]],
      regexp: [:except, %w[list bool date user version]],
      searchable: [:except, %w[bool date float int user version]],
      textOrientation: [:only, %w[text]]
    }.freeze

    def self.stimulus_config
      CONFIG.map { |target_name, (operator, formats)| [target_name, operator, formats] }.to_json
    end

    attr_reader :format

    def initialize(format)
      @format = format
    end

    def attributes(target_name)
      operator, formats = CONFIG[target_name.to_sym]

      fail ArgumentError, "Unknown target name #{target_name}" unless formats

      visible = operator == :only ? format.in?(formats) : !format.in?(formats)

      ApplicationController.helpers.tag.attributes(
        data: { "admin--custom-fields-target": target_name },
        hidden: !visible
      )
    end
  end
end
