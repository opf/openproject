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

require_relative "journal_formatter_cache"
require_relative "journal_formatter/base"
require_relative "journal_formatter/attribute"
require_relative "journal_formatter/chronic_duration"
require_relative "journal_formatter/datetime"
require_relative "journal_formatter/day_count"
require_relative "journal_formatter/decimal"
require_relative "journal_formatter/fraction"
require_relative "journal_formatter/id"
require_relative "journal_formatter/named_association"
require_relative "journal_formatter/percentage"
require_relative "journal_formatter/plaintext"

module JournalFormatter
  mattr_accessor :formatters, :registered_fields

  def self.register(hash)
    formatters.merge!(hash)
  end

  def self.register_formatted_field(journal_data_type, field, formatter_key)
    field_key = field.is_a?(Regexp) ? field : Regexp.new("^#{field}$")

    registered_fields[journal_data_type].merge!(field_key => formatter_key.to_sym)
  end

  def self.default_formatters
    {
      chronic_duration: JournalFormatter::ChronicDuration,
      datetime: JournalFormatter::Datetime,
      day_count: JournalFormatter::DayCount,
      decimal: JournalFormatter::Decimal,
      fraction: JournalFormatter::Fraction,
      id: JournalFormatter::Id,
      named_association: JournalFormatter::NamedAssociation,
      percentage: JournalFormatter::Percentage,
      plaintext: JournalFormatter::Plaintext
    }
  end

  self.formatters = default_formatters
  self.registered_fields = Hash.new do |hash, journal_data_type|
    hash[journal_data_type] = {}
  end

  def render_detail(detail, options = {})
    options = options.reverse_merge(html: true, only_path: true, cache: JournalFormatterCache.request_instance)

    if detail.respond_to? :to_ary
      field = detail.first
      values = detail.last
    else
      field = detail
      values = details[field.to_s]
    end

    formatter = formatter_instance(field)

    return if formatter.nil?

    formatter
      .render(field, values, options)
      &.html_safe # rubocop:disable Rails/OutputSafety
  end

  def formatter_instance(field)
    # Some attributes on a model are named dynamically.
    # This is especially true for associations created by plugins.
    # Those are sometimes named according to the schema "association_name[n]" or
    # "association_name_[n]" where n is an integer representing an id.
    # Using regexp we are able to handle those fields with the rest.
    formatter_key = lookup_formatter_key(field)

    formatter_instances[formatter_key] if formatter_key
  end

  def journal_data_type
    data_type
  end

  def lookup_formatter_key(field)
    JournalFormatter
      .registered_fields[journal_data_type]
      .find { |regexp, _formatter_key| field.match(regexp) }
      .then { |_regexp, formatter_key| formatter_key }
  end

  def formatter_instances
    @formatter_instances ||= Hash.new do |hash, formatter_key|
      formatter_class = JournalFormatter.formatters[formatter_key]
      hash[formatter_key] = formatter_class.new(self)
    end
  end
end
