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

module OpenProject::ActiveModelErrorsPatch
  ##
  # ActiveRecord errors do provide no means to access the symbols initially used to create an
  # error. E.g. errors.add :foo, :bar instantly translates :bar, making it hard to write code
  # dependent on specific errors (which we use in the APIv3).
  # We therefore add a second information store containing pairs of [symbol, translated_message].
  def add(attribute, message = :invalid, options = {})
    error_symbol = options.fetch(:error_symbol) { message }
    super(attribute, message, options)

    if store_new_symbols?
      if error_symbol.is_a?(Symbol)
        symbol = error_symbol
        partial_message = normalize_message(attribute, message, options)
        full_message = full_message(attribute, partial_message)
      else
        symbol = :unknown
        full_message = message
      end

      writable_symbols_and_messages_for(attribute) << [symbol, full_message, partial_message]
    end
  end

  def symbols_and_messages_for(attribute)
    writable_symbols_and_messages_for(attribute).dup
  end

  def symbols_for(attribute)
    symbols_and_messages_for(attribute).map(&:first)
  end

  def full_message(attribute, message)
    return message if attribute == :base

    # if a model acts_as_customizable it will inject attributes like 'custom_field_1' into itself
    # using attr_name_override we resolve names of such attributes.
    # The rest of the method should reflect the original method implementation of ActiveModel
    attr_name_override = nil
    match = /\Acustom_field_(?<id>\d+)\z/.match(attribute)
    if match
      attr_name_override = CustomField.find_by(id: match[:id]).name
    end

    attr_name = attribute.to_s.tr('.', '_').humanize
    attr_name = @base.class.human_attribute_name(attribute, default: attr_name)
    I18n.t(:"errors.format",                                default: '%{attribute} %{message}',
                                                            attribute: attr_name_override || attr_name,
                                                            message: message)
  end

  # Need to do the house keeping along with AR::Errors
  # so that the symbols are removed when a new validation round starts
  def clear
    super

    @error_symbols = Hash.new
  end

  private

  def error_symbols
    @error_symbols ||= Hash.new
  end

  def writable_symbols_and_messages_for(attribute)
    error_symbols[attribute.to_sym] ||= []
  end

  # Kind of a hack: We need the possibility to temporarily disable symbol storing in the subclass
  # Reform::Contract::Errors, because otherwise we end up with duplicate entries
  # I feel dirty for doing that, but on the other hand I see no other way out... Please, stop me!
  def store_new_symbols?
    @store_new_symbols = true if @store_new_symbols.nil?
    @store_new_symbols
  end
end

ActiveModel::Errors.prepend(OpenProject::ActiveModelErrorsPatch)
