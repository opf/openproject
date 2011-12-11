#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++


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

      errors = errors_including_custom_values

      errors.each_key do |attr|
        errors[attr].each do |message|
          next unless message

          if attr == "base"
            full_messages << message
          else
            attr_name = @base.respond_to?(attr) ? @base.class.human_attribute_name(attr) : attr
            full_messages << attr_name + ' ' + message.to_s
          end
        end
      end
      full_messages
    end

    def errors_including_custom_values
      errors = @errors.dup

      if errors["custom_values"].present?
        @base.custom_values.select{ |v| v.errors.length > 0 }.each do |value|
          errors[value.custom_field.name] = value.errors.instance_variable_get("@errors").values
        end

        errors.delete("custom_values")
      end

      errors
    end
  end
end

module ActionView
  module Helpers
    module ActiveRecordHelper
      def error_messages_for(*params)
        options = params.extract_options!.symbolize_keys

        if object = options.delete(:object)
          objects = Array.wrap(object)
        else
          objects = params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
        end


        count  = objects.inject(0) {|sum, object| sum + object.errors.count }
        unless count.zero?
          html = {}
          [:id, :class].each do |key|
            if options.include?(key)
              value = options[key]
              html[key] = value unless value.blank?
            else
              html[key] = 'errorExplanation'
            end
          end
          options[:object_name] ||= params.first

          I18n.with_options :locale => options[:locale], :scope => [:activerecord, :errors, :template] do |locale|
            header_message = if options.include?(:header_message)
              options[:header_message]
            else
              object_name = options[:object_name].to_s
              object_name = I18n.t(object_name, :default => object_name.gsub('_', ' '), :scope => [:activerecord, :models], :count => 1)
              locale.t :header, :count => count, :model => object_name
            end
            message = options.include?(:message) ? options[:message] : locale.t(:body)

            error_messages = objects.sum {|object| object.errors.full_messages.each_with_index.map do |msg,index|
              # Generating unique identifier in order to jump directly to the field with the error
              object_identifier = (object_name.parameterize("_")).to_s  + "_" + (object.errors.to_a.at(index).first) + "_error"
              content_tag(:li, content_tag(:a,(ERB::Util.html_escape(msg)), :href => "#" + object_identifier, :class => "afocus"))
            end}.join.html_safe

            contents = ''
            contents << content_tag(options[:header_tag] || :h2, header_message) unless header_message.blank?
            contents << content_tag(:p, message) unless message.blank?
            contents << content_tag(:ul, error_messages)

            content_tag(:div, contents.html_safe, html)
          end
        else
          ''
        end
      end
    end

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

ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  if html_tag.include?("<label")
    html_tag.to_s
  else
    object_identifier = (instance.instance_variable_get("@object_name").parameterize).to_s + "_" + (instance.instance_variable_get("@method_name"))

    # select boxes used name_id whereas the validation uses name
    # we have to cut the '_id' of in order for the field to match
    if (html_tag.include?("<select") or html_tag.include?('type="checkbox"'))
      object_identifier = object_identifier[0..-4]
    end
    object_identifier = object_identifier + "_error"
    "<span id='#{object_identifier}' class=\"errorSpan\"><a name=\"#{object_identifier}\"></a>#{html_tag}</span>"
  end
end

class ActiveRecord::Errors
  def on_with_id_handling(attribute)
    attribute = attribute.to_s
    if attribute.ends_with? '_id'
      on_without_id_handling(attribute) || on_without_id_handling(attribute[0..-4])
    else
      on_without_id_handling(attribute)
    end
  end

  alias_method_chain :on, :id_handling
end

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
