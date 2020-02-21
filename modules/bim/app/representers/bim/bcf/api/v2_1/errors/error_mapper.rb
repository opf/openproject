#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Bim::Bcf::API::V2_1::Errors
  class ErrorMapper
    extend ActiveModel::Naming
    extend ActiveModel::Translation

    def read_attribute_for_validation(_attr)
      nil
    end

    # In case the error lookups collide, we need to provide
    # separate error mappers for every class.
    def self.lookup_ancestors
      [::Bim::Bcf::Issue, ::Bim::Bcf::Viewpoint]
    end

    def self.map(original_errors)
      mapped_errors = ActiveModel::Errors.new(new)

      original_errors.send(:error_symbols).each do |key, errors|
        errors.map(&:first).each do |error|
          mapped_errors.add(error_key_mapper(key), error)
        end
      end

      mapped_errors
    end

    def self.i18n_scope
      :activerecord
    end

    def self.error_key_mapper(key)
      { subject: :title,
        json_viewpoint: :base }[key] || key
    end
  end
end
