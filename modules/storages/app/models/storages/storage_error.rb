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

module Storages
  class StorageError
    extend ActiveModel::Naming

    attr_reader :code, :log_message, :data

    # @param code [Symbol, Integer]
    # @param log_message: [String]
    # @param data [Storages::StoragesErrorData]
    def initialize(code:, log_message: nil, data: nil)
      @code = code
      @log_message = log_message
      @data = data
    end

    def to_active_model_errors
      errors = ActiveModel::Errors.new(self)
      errors.add(:storage_error, code, message: log_message)
      errors
    end

    def to_s
      output = code.to_s
      output << " | #{log_message}" unless log_message.nil?
      output << " | #{data}" unless data.nil?
      output
    end

    def read_attribute_for_validation(attr)
      attr.to_s
    end

    def self.human_attribute_name(attr, _options = {}) = attr

    def self.lookup_ancestors = [self]
  end
end
