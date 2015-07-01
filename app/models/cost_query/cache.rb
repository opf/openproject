#-- copyright
# OpenProject Reporting Plugin
#
# Copyright (C) 2010 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

module CostQuery::Cache
  class << self

    def check
      reset! if invalid?
    end

    def reset!
      CostQuery::Filter.reset!
      CostQuery::Filter::CustomFieldEntries.reset!
      CostQuery::GroupBy.reset!
      CostQuery::GroupBy::CustomFieldEntries.reset!

      update_reset_on
    end

    protected

    attr_accessor :custom_fields_updated_on,
                  :custom_fields_id_sum

    def invalid?
      updated_on = fetch_custom_field_updated_at
      id_sum = fetch_custom_fields_changed

      custom_fields_exist = updated_on && id_sum
      custom_fields_changed = custom_fields_updated_on != updated_on ||
                                custom_fields_id_sum != id_sum

      custom_fields_exist && custom_fields_changed
    end

    def update_reset_on
      self.custom_fields_updated_on = fetch_custom_field_updated_at
      self.custom_fields_id_sum = fetch_custom_fields_changed
    end

    def fetch_custom_field_updated_at
      WorkPackageCustomField.maximum(:updated_at)
    end

    def fetch_custom_fields_changed
      WorkPackageCustomField.sum(:id) + WorkPackageCustomField.count
    end
  end
end
