#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Queries::Operators
  class Base
    class_attribute :label_key,
                    :symbol,
                    :value_required

    self.value_required = true

    def self.label(label)
      self.label_key = "label_#{label}"
    end

    def self.set_symbol(sym)
      self.symbol = sym
    end

    def self.require_value(value)
      self.value_required = value
    end

    def self.requires_value?
      value_required
    end

    def self.sql_for_field(_values, _db_table, _db_field)
      raise NotImplementedError
    end

    def self.connection
      ActiveRecord::Base.connection
    end

    def self.to_sym
      symbol.to_sym
    end

    def self.human_name
      I18n.t(label_key)
    end

    def self.to_query
      CGI.escape(symbol.to_s)
    end
  end
end
