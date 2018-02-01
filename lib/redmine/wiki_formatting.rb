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

module Redmine
  module WikiFormatting
    class << self

      def registered
        unless defined? @formatters
          register_default!
        end

        @formatters
      end

      def registered?(key)
        registered.key? key.to_sym
      end

      def register(namespace:)
        # Force lookup to avoid const errors later on.
        key = namespace.to_sym
        modulename = namespace.to_s.classify

        raise ArgumentError, "format name '#{name}' is already taken" if registered?(key)

        begin
          formatter = "Redmine::WikiFormatting::#{modulename}::Formatter".constantize
          helper = "Redmine::WikiFormatting::#{modulename}::Helper".constantize
          registered[key] = { formatter: formatter, helper: helper }
        rescue NameError => e
          Rails.logger.error "Failed to register wiki formatting #{namespace}: #{e}"
          Rails.logger.debug { e.backtrace }
        end
      end

      def formatter_for(name)
        entry = registered.fetch(name.to_sym) { registered[:null_formatter] }
        entry[:formatter]
      end

      def helper_for(name)
        entry = registered.fetch(name.to_sym) { registered[:null_formatter] }
        entry[:helper]
      end

      def format_names
        registered.keys.map
      end

      def to_html(format, text, options = {}, &block)
        edit = !!options[:edit]
        text = if Setting.cache_formatted_text? && text.size > 2.kilobyte && cache_store && cache_key = cache_key_for(format, options[:object], options[:attribute], edit)
                 # Text retrieved from the cache store may be frozen
                 # We need to dup it so we can do in-place substitutions with gsub!
                 cache_store.fetch cache_key do
                   formatter_for(format).new(text).to_html edit ? :edit : nil
                 end.dup
               else
                 formatter_for(format).new(text).to_html edit ? :edit : nil
        end
        text
      end

      # Returns a cache key for the given text +format+, +object+ and +attribute+ or nil if no caching should be done
      def cache_key_for(format, object, attribute, edit)
        if object && attribute && edit && !object.new_record? && object.respond_to?(:updated_on) && !format.blank?
          "formatted_text/#{format}/#{object.class.model_name.cache_key}/#{object.id}-#{attribute}-#{edit}-#{object.updated_on.to_s(:number)}"
        end
      end

      # Returns the cache store used to cache HTML output
      def cache_store
        ActionController::Base.cache_store
      end

      private

      def register_default!
        @formatters = {}
        register namespace: :null_formatter
        register namespace: :textile
      end
    end
  end
end
