#-- encoding: UTF-8
#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2013 the ChiliProject Team
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

    module FormHelper
      # Returns an input tag of the "date" type tailored for accessing a specified attribute (identified by +method+) on an object
      # assigned to the template (identified by +object+). Additional options on the input tag can be passed as a
      # hash with +options+. These options will be tagged onto the HTML as an HTML element attribute as in the example
      # shown.
      #
      # ==== Examples
      #   date_field(:user, :birthday, :size => 20)
      #   # => <input type="date" id="user_birthday" name="user[birthday]" size="20" value="#{@user.birthday}" />
      #
      #   date_field(:user, :birthday, :class => "create_input")
      #   # => <input type="date" id="user_birthday" name="user[birthday]" value="#{@user.birthday}" class="create_input" />
      #
      # NOTE: This will be part of rails 4.0, the monkey patch can be removed by then.
      def date_field(object_name, method, options = {})
        InstanceTag.new(object_name, method, self, options.delete(:object)).to_input_field_tag("date", options)
      end
    end

    # As ActionPacks metaprogramming will already have happened when we're here,
    # we have to tell the FormBuilder about the above date_field ourselvse
    #
    # NOTE: This can be remove when the above ActionView::Helpers::FormHelper#date_field is removed
    class FormBuilder
      self.field_helpers << "date_field"

      def date_field(method, options = {})
        @template.date_field(@object_name, method, objectify_options(options))
      end
    end

    module FormTagHelper
      # Creates a date form input field.
      #
      # ==== Options
      # * Creates standard HTML attributes for the tag.
      #
      # ==== Examples
      #   date_field_tag 'meeting_date'
      #   # => <input id="meeting_date" name="meeting_date" type="date" />
      #
      # NOTE: This will be part of rails 4.0, the monkey patch can be removed by then.
      def date_field_tag(name, value = nil, options = {})
        text_field_tag(name, value, options.stringify_keys.update("type" => "date"))
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

  # Backported fix for
  # CVE-2012-2660
  # https://groups.google.com/group/rubyonrails-security/browse_thread/thread/f1203e3376acec0f
  #
  # CVE-2012-2694
  # https://groups.google.com/group/rubyonrails-security/browse_thread/thread/8c82d9df8b401c5e
  #
  # TODO: Remove this once we are on Rails >= 3.2.6
  require 'action_controller/request'
  class Request
    protected

    # Remove nils from the params hash
    def deep_munge(hash)
      keys = hash.keys.find_all { |k| hash[k] == [nil] }
      keys.each { |k| hash[k] = nil }

      hash.each_value do |v|
        case v
        when Array
          v.grep(Hash) { |x| deep_munge(x) }
          v.compact!
        when Hash
          deep_munge(v)
        end
      end

      hash
    end

    def parse_query(qs)
      deep_munge(super)
    end
  end
end

require 'active_record/base'
module ActiveRecord
  class Base
    class << self
      # Backported fix for CVE-2012-2695
      # https://groups.google.com/group/rubyonrails-security/browse_thread/thread/9782f44c4540cf59
      # TODO: Remove this once we are on Rails >= 3.2.6
      def sanitize_sql_hash_for_conditions(attrs, default_table_name = quoted_table_name, top_level = true)
        attrs = expand_hash_conditions_for_aggregates(attrs)

        conditions = attrs.map do |attr, value|
          table_name = default_table_name

          if not value.is_a?(Hash)
            attr = attr.to_s

            # Extract table name from qualified attribute names.
            if attr.include?('.') and top_level
              attr_table_name, attr = attr.split('.', 2)
              attr_table_name = connection.quote_table_name(attr_table_name)
            else
              attr_table_name = table_name
            end

            attribute_condition("#{attr_table_name}.#{connection.quote_column_name(attr)}", value)
          elsif top_level
            sanitize_sql_hash_for_conditions(value, connection.quote_table_name(attr.to_s), false)
          else
            raise ActiveRecord::StatementInvalid
          end
        end.join(' AND ')

        replace_bind_variables(conditions, expand_range_bind_variables(attrs.values))
      end
      alias_method :sanitize_sql_hash, :sanitize_sql_hash_for_conditions

      # CVE-2012-5664
      # https://groups.google.com/forum/?fromgroups=#!topic/rubyonrails-security/DCNTNp_qjFM
      # TODO: remove once we are on Rails >= 3.2.10
      def method_missing(method_id, *arguments, &block)
        if match = DynamicFinderMatch.match(method_id)
          attribute_names = match.attribute_names
          super unless all_attributes_exists?(attribute_names)
          if match.finder?
            finder = match.finder
            bang = match.bang?
            # def self.find_by_login_and_activated(*args)
            #   options = args.extract_options!
            #   attributes = construct_attributes_from_arguments(
            #     [:login,:activated],
            #     args
            #   )
            #   finder_options = { :conditions => attributes }
            #   validate_find_options(options)
            #   set_readonly_option!(options)
            #
            #   if options[:conditions]
            #     with_scope(:find => finder_options) do
            #       find(:first, options)
            #     end
            #   else
            #     find(:first, options.merge(finder_options))
            #   end
            # end
            self.class_eval <<-EOS, __FILE__, __LINE__ + 1
              def self.#{method_id}(*args)
                options = if args.length > #{attribute_names.size}
                            args.extract_options!
                          else
                            {}
                          end
                attributes = construct_attributes_from_arguments(
                  [:#{attribute_names.join(',:')}],
                  args
                )
                finder_options = { :conditions => attributes }
                validate_find_options(options)
                set_readonly_option!(options)

                #{'result = ' if bang}if options[:conditions]
                  with_scope(:find => finder_options) do
                    find(:#{finder}, options)
                  end
                else
                  find(:#{finder}, options.merge(finder_options))
                end
                #{'result || raise(RecordNotFound, "Couldn\'t find #{name} with #{attributes.to_a.collect {|pair| "#{pair.first} = #{pair.second}"}.join(\', \')}")' if bang}
              end
            EOS
            send(method_id, *arguments)
          elsif match.instantiator?
            instantiator = match.instantiator
            # def self.find_or_create_by_user_id(*args)
            #   guard_protected_attributes = false
            #
            #   if args[0].is_a?(Hash)
            #     guard_protected_attributes = true
            #     attributes = args[0].with_indifferent_access
            #     find_attributes = attributes.slice(*[:user_id])
            #   else
            #     find_attributes = attributes = construct_attributes_from_arguments([:user_id], args)
            #   end
            #
            #   options = { :conditions => find_attributes }
            #   set_readonly_option!(options)
            #
            #   record = find(:first, options)
            #
            #   if record.nil?
            #     record = self.new { |r| r.send(:attributes=, attributes, guard_protected_attributes) }
            #     yield(record) if block_given?
            #     record.save
            #     record
            #   else
            #     record
            #   end
            # end
            self.class_eval <<-EOS, __FILE__, __LINE__ + 1
              def self.#{method_id}(*args)
                attributes = [:#{attribute_names.join(',:')}]
                protected_attributes_for_create, unprotected_attributes_for_create = {}, {}
                args.each_with_index do |arg, i|
                  if arg.is_a?(Hash)
                    protected_attributes_for_create = args[i].with_indifferent_access
                  else
                    unprotected_attributes_for_create[attributes[i]] = args[i]
                  end
                end

                find_attributes = (protected_attributes_for_create.merge(unprotected_attributes_for_create)).slice(*attributes)

                options = { :conditions => find_attributes }
                set_readonly_option!(options)

                record = find(:first, options)

                if record.nil?
                  record = self.new do |r|
                    r.send(:attributes=, protected_attributes_for_create, true) unless protected_attributes_for_create.empty?
                    r.send(:attributes=, unprotected_attributes_for_create, false) unless unprotected_attributes_for_create.empty?
                  end
                  #{'yield(record) if block_given?'}
                  #{'record.save' if instantiator == :create}
                  record
                else
                  record
                end
              end
            EOS
            send(method_id, *arguments, &block)
          end
        elsif match = DynamicScopeMatch.match(method_id)
          attribute_names = match.attribute_names
          super unless all_attributes_exists?(attribute_names)
          if match.scope?
            self.class_eval <<-EOS, __FILE__, __LINE__ + 1
              def self.#{method_id}(*args)                        # def self.scoped_by_user_name_and_password(*args)
                options = args.extract_options!                   #   options = args.extract_options!
                attributes = construct_attributes_from_arguments( #   attributes = construct_attributes_from_arguments(
                  [:#{attribute_names.join(',:')}], args          #     [:user_name, :password], args
                )                                                 #   )
                                                                  #
                scoped(:conditions => attributes)                 #   scoped(:conditions => attributes)
              end                                                 # end
            EOS
            send(method_id, *arguments)
          end
        else
          super
        end
      end
    end
  end
end

# Backported fix for CVE-2012-3465
# https://groups.google.com/d/msg/rubyonrails-security/FgVEtBajcTY/tYLS1JJTu38J
# TODO: Remove this once we are on Rails >= 3.2.8
require 'action_view/helpers/sanitize_helper'
module ActionView::Helpers::SanitizeHelper
  def strip_tags(html)
    self.class.full_sanitizer.sanitize(html)
  end
end

# Backported fix for CVE-2012-3464
# https://groups.google.com/d/msg/rubyonrails-security/kKGNeMrnmiY/r2yM7xy-G48J
# TODO: Remove this once we are on Rails >= 3.2.8
require 'active_support/core_ext/string/output_safety'
class ERB
  module Util
    HTML_ESCAPE["'"] = '&#39;'

    if RUBY_VERSION >= '1.9'
      # A utility method for escaping HTML tag characters.
      # This method is also aliased as <tt>h</tt>.
      #
      # In your ERB templates, use this method to escape any unsafe content. For example:
      # <%=h @person.name %>
      #
      # ==== Example:
      # puts html_escape("is a > 0 & a < 10?")
      # # => is a &gt; 0 &amp; a &lt; 10?
      def html_escape(s)
        s = s.to_s
        if s.html_safe?
          s
        else
          s.gsub(/[&"'><]/, HTML_ESCAPE).html_safe
        end
      end
    else
      def html_escape(s) #:nodoc:
        s = s.to_s
        if s.html_safe?
          s
        else
          s.gsub(/[&"'><]/n) { |special| HTML_ESCAPE[special] }.html_safe
        end
      end
    end

    # Aliasing twice issues a warning "discarding old...". Remove first to avoid it.
    remove_method(:h)
    alias h html_escape

    module_function :h

    singleton_class.send(:remove_method, :html_escape)
    module_function :html_escape
  end
end
require 'action_view/helpers/tag_helper'
module ActionView::Helpers::TagHelper
  def escape_once(html)
    ActiveSupport::Multibyte.clean(html.to_s).gsub(/[\"\'><]|&(?!([a-zA-Z]+|(#\d+));)/) { |special| ERB::Util::HTML_ESCAPE[special] }
  end
end
