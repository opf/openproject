#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2012 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

# Patches active_support/core_ext/load_error.rb to support 1.9.3 LoadError message
if RUBY_VERSION >= '1.9.3'
  MissingSourceFile::REGEXPS << [/^cannot load such file -- (.+)$/i, 1]
end

require 'active_record'

module ActiveRecord
  class Base
    include Redmine::I18n

    # Translate attribute names for validation errors display
    def self.human_attribute_name(attr)
      l("field_#{attr.to_s.gsub(/_id$/, '')}")
    end
  end
end

module ActiveRecord
  class Errors
    def full_messages(options = {})
      full_messages = []

      @errors.each_key do |attr|
        @errors[attr].each do |message|
          next unless message

          if attr == "base"
            full_messages << message
          elsif attr == "custom_values"
            # Replace the generic "custom values is invalid"
            # with the errors on custom values
            @base.custom_values.each do |value|
              value.errors.each do |attr, msg|
                full_messages << value.custom_field.name + ' ' + msg
              end
            end
          else
            attr_name = @base.class.human_attribute_name(attr)
            full_messages << attr_name + ' ' + message.to_s
          end
        end
      end
      full_messages
    end
  end
end

module ActionView
  module Helpers
    module DateHelper
      # distance_of_time_in_words breaks when difference is greater than 30 years
      def distance_of_date_in_words(from_date, to_date = 0, options = {})
        from_date = from_date.to_date if from_date.respond_to?(:to_date)
        to_date = to_date.to_date if to_date.respond_to?(:to_date)
        distance_in_days = (to_date - from_date).abs

        I18n.with_options :locale => options[:locale], :scope => :'datetime.distance_in_words' do |locale|
          case distance_in_days
            when 0..60     then locale.t :x_days,             :count => distance_in_days.round
            when 61..720   then locale.t :about_x_months,     :count => (distance_in_days / 30).round
            else                locale.t :over_x_years,       :count => (distance_in_days / 365).floor
          end
        end
      end
    end
  end
end

ActionView::Base.field_error_proc = Proc.new{ |html_tag, instance| "#{html_tag}" }

# Adds :async_smtp and :async_sendmail delivery methods
# to perform email deliveries asynchronously
module AsynchronousMailer
  %w(smtp sendmail).each do |type|
    define_method("perform_delivery_async_#{type}") do |mail|
      Thread.start do
        send "perform_delivery_#{type}", mail
      end
    end
  end
end

ActionMailer::Base.send :include, AsynchronousMailer

# TMail::Unquoter.convert_to_with_fallback_on_iso_8859_1 introduced in TMail 1.2.7
# triggers a test failure in test_add_issue_with_japanese_keywords(MailHandlerTest)
module TMail
  class Unquoter
    class << self
      alias_method :convert_to, :convert_to_without_fallback_on_iso_8859_1
    end
  end
end

module ActionController
  module MimeResponds
    class Responder
      def api(&block)
        any(:xml, :json, &block)
      end
    end
  end
end
