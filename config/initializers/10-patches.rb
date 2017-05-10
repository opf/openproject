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

require 'active_record'

module ActiveRecord
  class Base
    include Redmine::I18n

    # Translate attribute names for validation errors display
    def self.human_attribute_name(attr, options = {})
      options_with_raise = { raise: true, default: false }.merge options
      attr = attr.to_s.gsub(/_id\z/, '')
      super(attr, options_with_raise)
    rescue I18n::MissingTranslationData => e
      included_in_general_attributes = I18n.t('attributes').keys.map(&:to_s).include? attr
      included_in_superclasses = ancestors.select { |a| a.ancestors.include? ActiveRecord::Base }.any? { |klass| !(I18n.t("activerecord.attributes.#{klass.name.underscore}.#{attr}").include? 'translation missing:') }
      unless included_in_general_attributes or included_in_superclasses
        # TODO: remove this method once no warning is displayed when running a server/console/tests/tasks etc.
        warn "[DEPRECATION] Relying on Redmine::I18n addition of `field_` to your translation key \"#{attr}\" on the \"#{self}\" model is deprecated. Please use proper ActiveRecord i18n! \n Caught: #{e.message}"
      end
      super(attr, options)
    end
  end
end

module ActiveModel
  class Errors
    ##
    # ActiveRecord errors do provide no means to access the symbols initially used to create an
    # error. E.g. errors.add :foo, :bar instantly translates :bar, making it hard to write code
    # dependent on specific errors (which we use in the APIv3).
    # We therefore add a second information store containing pairs of [symbol, translated_message].
    def add_with_storing_error_symbols(attribute, message = :invalid, options = {})
      error_symbol = options.fetch(:error_symbol) { message }
      add_without_storing_error_symbols(attribute, message, options)

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

    alias_method_chain :add, :storing_error_symbols

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

      attr_name = attribute.to_s.gsub('.', '_').humanize
      attr_name = @base.class.human_attribute_name(attribute, default: attr_name)
      I18n.t(:"errors.format",                                default: '%{attribute} %{message}',
                                                              attribute: attr_name_override || attr_name,
                                                              message: message)
    end

    # Need to do the house keeping along with AR::Errors
    # so that the symbols are removed when a new validation round starts
    def clear_with_storing_error_symbols
      clear_without_storing_error_symbols

      @error_symbols = Hash.new
    end

    alias_method_chain :clear, :storing_error_symbols

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
end

module ActionView
  module Helpers
    module Tags
      Base.class_eval do
        attr_reader :method_name
      end
    end

    module AccessibleErrors
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def wrap_with_error_span(html_tag, object, method)
          object_identifier = erroneous_object_identifier(object.object_id.to_s, method)

          "<span id='#{object_identifier}' class=\"errorSpan\"><a name=\"#{object_identifier}\"></a>#{html_tag}</span>".html_safe
        end

        def erroneous_object_identifier(id, method)
          # select boxes use name_id whereas the validation uses name
          # we have to cut the '_id' of in order for the field to match
          id + '_' + method.gsub('_id', '') + '_error'
        end
      end

      module InstanceMethods
        def error_message_list(objects)
          objects.map do |object|
            error_messages = []

            object.errors.each_error do |attr, error|
              unless attr == 'custom_values'
                # Generating unique identifier in order to jump directly to the field with the error
                object_identifier = erroneous_object_identifier(object.object_id.to_s, attr)

                error_messages << [object.class.human_attribute_name(attr) + ' ' + error.message, object_identifier]
              end
            end

            # excluding custom_values from the errors.each loop before
            # as more than one error can be assigned to custom_values
            # which would add to many error messages
            if object.errors[:custom_values].any?
              object.custom_values.each do |value|
                value.errors.map do |attr, msg|
                  # Generating unique identifier in order to jump directly to the field with the error
                  object_identifier = erroneous_object_identifier(value.object_id.to_s, attr)
                  error_messages << [value.custom_field.name + ' ' + msg, object_identifier]
                end
              end
            end

            error_message_list_elements(error_messages)
          end
        end

        private

        def erroneous_object_identifier(id, method)
          self.class.erroneous_object_identifier(id, method)
        end

        def error_message_list_elements(array)
          array.map do |msg, identifier|
            content_tag :li do
              content_tag :a,
                          ERB::Util.html_escape(msg),
                          href: '#' + identifier,
                          class: 'afocus'
            end
          end
        end
      end
    end

    module DateHelper
      # distance_of_time_in_words breaks when difference is greater than 30 years
      def distance_of_date_in_words(from_date, to_date = 0, options = {})
        from_date = from_date.to_date if from_date.respond_to?(:to_date)
        to_date = to_date.to_date if to_date.respond_to?(:to_date)
        distance_in_days = (to_date - from_date).abs

        I18n.with_options locale: options[:locale], scope: :'datetime.distance_in_words' do |locale|
          case distance_in_days
          when 0..60     then locale.t :x_days,             count: distance_in_days.round
          when 61..720   then locale.t :about_x_months,     count: (distance_in_days / 30).round
          else                locale.t :over_x_years,       count: (distance_in_days / 365).floor
          end
        end
      end
    end

    module AssetTagHelper
      def auto_discovery_link_tag_with_no_atom_feeds(type = :rss, url_options = {}, tag_options = {})
        return if (type == :atom) && Setting.table_exists? && !Setting.feeds_enabled?
        auto_discovery_link_tag_without_no_atom_feeds(type, url_options, tag_options)
      end
      alias_method_chain :auto_discovery_link_tag, :no_atom_feeds
    end
  end
end

ActionView::Base.send :include, ActionView::Helpers::AccessibleErrors

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  if html_tag.include?('<label')
    html_tag.to_s
  else
    ActionView::Base.wrap_with_error_span(html_tag, instance.object, instance.method_name)
  end
end

# Patch acts_as_list before any class includes the module
require 'open_project/patches/acts_as_list'

# Backports some useful ruby 2.3 methods for Hash
require 'open_project/patches/hash'
