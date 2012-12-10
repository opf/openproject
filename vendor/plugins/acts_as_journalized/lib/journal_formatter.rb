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
      registered_fields[klazz] ||= {}
      registered_fields[klazz].merge!(hash)
    else
      formatters.merge!(hash)
    end
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
  self.registered_fields = {}

  def render_detail(detail, no_html=false)
    if detail.respond_to? :to_ary
      key = detail.first
      values = detail.last
    else
      key = detail
      values = details[key.to_s]
    end

    # this is plain ugly but needed for attachments and custom_values as each instance has it's own association of the format
    # attachments[n], custom_values[n]
    formatter_key = JournalFormatter.registered_fields[self.class.name.to_sym].keys.detect{ |k| key.start_with?(k) }

    formatter = JournalFormatter.formatters[JournalFormatter.registered_fields[self.class.name.to_sym][formatter_key]]

    formatter_instance = formatter.new(self)

    formatter_instance.render(key, values, no_html)
  end
end
