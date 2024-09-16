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

module WorkPackage::Exports
  class CSV < QueryExporter
    include ::Exports::Concerns::CSV

    alias :records :work_packages

    private

    def title
      query.new_record? ? I18n.t(:label_work_package_plural) : query.name
    end

    def csv_headers
      return super unless with_descriptions

      super + [WorkPackage.human_attribute_name(:description)]
    end

    def with_descriptions
      ActiveModel::Type::Boolean.new.cast(options[:show_descriptions])
    end

    # fetch all row values
    def csv_row(work_package)
      return super unless with_descriptions

      super.tap do |row|
        if row.any?
          row << if work_package.description
                   work_package.description.squish
                 else
                   ""
                 end
        end
      end
    end
  end
end
