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

module JournalFormatter
  unloadable
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
    field_key = field.is_a?(Regexp) ? field : Regexp.new(field.to_s)

    registered_fields[klass].merge!(field => formatter)
  end

  # TODO: Document Formatters (can take up to three params, value, journaled, field ...)
  def self.default_formatters
    { :plaintext => JournalFormatter::Plaintext,
      :datetime => JournalFormatter::Datetime,
      :named_association => JournalFormatter::NamedAssociation,
      :fraction => JournalFormatter::Fraction,
      :decimal => JournalFormatter::Decimal,
      :id => JournalFormatter::Id }
  end

  self.formatters = default_formatters
  self.registered_fields = Hash.new do |hash, klass|
    hash[klass] = {}
  end

  def render_detail(detail, no_html=false)
    if detail.respond_to? :to_ary
      key = detail.first
      values = detail.last
    else
      key = detail
      values = details[key.to_s]
    end

    # Some attributes on a model are named dynamically.
    # This is especially true for associations created by plugins. Those are sometimes nameed according to
    # the schema "association_name[n]" or "association_name_[n]" where n is an integer increased over time.
    # Using regexp we are able to handle those fields with the rest.
    formatter_key = JournalFormatter.registered_fields[self.class.name.to_sym].keys.detect{ |k| key.match(k.to_s) }

    return nil if formatter_key.nil?

    formatter = JournalFormatter.formatters[JournalFormatter.registered_fields[self.class.name.to_sym][formatter_key]]

    formatter_instance = formatter.new(self)

    formatter_instance.render(key, values, no_html)
  end
end
