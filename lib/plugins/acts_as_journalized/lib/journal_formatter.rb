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

#-- encoding: UTF-8
# This file is part of the acts_as_journalized plugin for the redMine
# project management software
#
# Copyright (C) 2010  Finn GmbH, http://finn.de
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either journal 2
# of the License, or (at your option) any later journal.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

# This module holds the formatting methods that each journal has.
# It provides the hooks to apply different formatting to the details
# of a specific journal.

require_relative './journal_formatter/base'
require_relative './journal_formatter/attribute'
require_relative './journal_formatter/datetime'
require_relative './journal_formatter/decimal'
require_relative './journal_formatter/fraction'
require_relative './journal_formatter/id'
require_relative './journal_formatter/named_association'
require_relative './journal_formatter/plaintext'
require_relative './journal_formatter/proc'

module JournalFormatter
  mattr_accessor :formatters, :registered_fields

  def self.register(hash)
    if hash[:class]
      klazz = hash.delete(:class)

      register_formatted_field(klazz, hash.keys.first, hash.values.first)
    else
      formatters.merge!(hash)
    end
  end

  def self.register_formatted_field(klass, field, formatter)
    field_key = field.is_a?(Regexp) ? field : Regexp.new("^#{field}$")

    registered_fields[klass].merge!(field_key => formatter)
  end

  def self.default_formatters
    { plaintext: JournalFormatter::Plaintext,
      datetime: JournalFormatter::Datetime,
      named_association: JournalFormatter::NamedAssociation,
      fraction: JournalFormatter::Fraction,
      decimal: JournalFormatter::Decimal,
      id: JournalFormatter::Id }
  end

  self.formatters = default_formatters
  self.registered_fields = Hash.new do |hash, klass|
    hash[klass] = {}
  end

  def render_detail(detail, options = {})
    merge_options = { no_html: false, only_path: true }.merge(options)

    if detail.respond_to? :to_ary
      key = detail.first
      values = detail.last
    else
      key = detail
      values = details[key.to_s]
    end

    formatter = formatter_instance(key.to_s)

    return nil if formatter.nil?

    formatter.render(key, values, merge_options).html_safe
  end

  def formatter_instance(formatter_key)
    # Some attributes on a model are named dynamically.
    # This is especially true for associations created by plugins.
    # Those are sometimes named according to the schema "association_name[n]" or
    # "association_name_[n]" where n is an integer representing an id.
    # Using regexp we are able to handle those fields with the rest.
    formatter_type = data.class.to_s.to_sym
    formatter = lookup_formatter formatter_key, formatter_type

    formatter_instances(formatter_type)[formatter] unless formatter.nil?
  end

  def lookup_formatter(formatter_key, formatter_type)
    JournalFormatter
      .registered_fields[formatter_type].keys
      .detect { |k| formatter_key.match(k) }
  end

  def formatter_instances(formatter_type)
    @formatter_instances ||= Hash.new do |hash, key|
      f = JournalFormatter.formatters[JournalFormatter.registered_fields[formatter_type][key]]
      hash[key] = f.new(self)
    end
  end
end
