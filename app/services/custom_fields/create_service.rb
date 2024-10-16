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

module CustomFields
  class CreateService < ::BaseServices::Create
    def self.careful_new_custom_field(type)
      if /.+CustomField\z/.match?(type.to_s)
        klass = type.to_s.constantize
        klass.new if klass.ancestors.include? CustomField
      end
    rescue NameError => e
      Rails.logger.error "#{e.message}:\n#{e.backtrace.join("\n")}"
      nil
    end

    def perform(params)
      super
    rescue StandardError => e
      ServiceResult.failure(message: e.message)
    end

    def instance(params)
      cf = self.class.careful_new_custom_field(params[:type])
      raise ArgumentError.new("Invalid CF type") unless cf

      cf
    end

    def after_perform(call)
      cf = call.result

      if cf.is_a?(ProjectCustomField)
        add_cf_to_visible_columns(cf)
      elsif cf.field_format_hierarchy?
        CustomFields::Hierarchy::HierarchicalItemService.new.generate_root(cf)
      end

      call
    end

    private

    def add_cf_to_visible_columns(custom_field)
      Setting.enabled_projects_columns = (Setting.enabled_projects_columns + [custom_field.column_name]).uniq
    end
  end
end
