# Copyright (c) 2005-2006 David Barri

require 'gloc'

module ActionController #:nodoc:
  class Base #:nodoc:
    include GLoc
  end
  module Filters #:nodoc:
    module ClassMethods

      # This filter attempts to auto-detect the clients desired language.
      # It first checks the params, then a cookie and then the HTTP_ACCEPT_LANGUAGE
      # request header. If a language is found to match or be similar to a currently
      # valid language, then it sets the current_language of the controller.
      # 
      #   class ExampleController < ApplicationController
      #     set_language :en
      #     autodetect_language_filter :except => 'monkey', :on_no_lang => :lang_not_autodetected_callback
      #     autodetect_language_filter :only => 'monkey', :check_cookie => 'monkey_lang', :check_accept_header => false
      #     ...
      #     def lang_not_autodetected_callback
      #       redirect_to somewhere
      #     end
      #   end
      # 
      # The <tt>args</tt> for this filter are exactly the same the arguments of
      # <tt>before_filter</tt> with the following exceptions:
      # * <tt>:check_params</tt> -- If false, then params will not be checked for a language.
      #   If a String, then this will value will be used as the name of the param.
      # * <tt>:check_cookie</tt> -- If false, then the cookie will not be checked for a language.
      #   If a String, then this will value will be used as the name of the cookie.
      # * <tt>:check_accept_header</tt> -- If false, then HTTP_ACCEPT_LANGUAGE will not be checked for a language.
      # * <tt>:on_set_lang</tt> -- You can specify the name of a callback function to be called when the language
      #   is successfully detected and set. The param must be a Symbol or a String which is the name of the function.
      #   The callback function must accept one argument (the language) and must be instance level.
      # * <tt>:on_no_lang</tt> -- You can specify the name of a callback function to be called when the language
      #   couldn't be detected automatically. The param must be a Symbol or a String which is the name of the function.
      #   The callback function must be instance level.
      #   
      # You override the default names of the param or cookie by calling <tt>GLoc.set_config :default_param_name => 'new_param_name'</tt>
      # and <tt>GLoc.set_config :default_cookie_name => 'new_cookie_name'</tt>.
      def autodetect_language_filter(*args)
        options= args.last.is_a?(Hash) ? args.last : {}
        x= 'Proc.new { |c| l= nil;'
        # :check_params
        unless (v= options.delete(:check_params)) == false
          name= v ? ":#{v}" : 'GLoc.get_config(:default_param_name)'
          x << "l ||= GLoc.similar_language(c.params[#{name}]);"
        end
        # :check_cookie
        unless (v= options.delete(:check_cookie)) == false
          name= v ? ":#{v}" : 'GLoc.get_config(:default_cookie_name)'
          x << "l ||= GLoc.similar_language(c.send(:cookies)[#{name}]);"
        end
        # :check_accept_header
        unless options.delete(:check_accept_header) == false
          x << %<
              unless l
                a= c.request.env['HTTP_ACCEPT_LANGUAGE'].split(/,|;/) rescue nil
                a.each {|x| l ||= GLoc.similar_language(x)} if a
              end; >
        end
        # Set language
        x << 'ret= true;'
        x << 'if l; c.set_language(l); c.headers[\'Content-Language\']= l.to_s; '
        if options.has_key?(:on_set_lang)
          x << "ret= c.#{options.delete(:on_set_lang)}(l);"
        end
        if options.has_key?(:on_no_lang)
          x << "else; ret= c.#{options.delete(:on_no_lang)};"
        end
        x << 'end; ret }'
        
        # Create filter
        block= eval x
        before_filter(*args, &block)
      end

    end
  end
end

# ==============================================================================

module ActionMailer #:nodoc:
  # In addition to including GLoc, <tt>render_message</tt> is also overridden so
  # that mail templates contain the current language at the end of the file.
  # Eg. <tt>deliver_hello</tt> will render <tt>hello_en.rhtml</tt>.
  class Base
    include GLoc
    private
    alias :render_message_without_gloc :render_message
    def render_message(method_name, body)
      render_message_without_gloc("#{method_name}_#{current_language}", body)
    end
  end
end

# ==============================================================================

module ActionView #:nodoc:
  # <tt>initialize</tt> is overridden so that new instances of this class inherit
  # the current language of the controller.
  class Base
    include GLoc
    
    alias :initialize_without_gloc :initialize
    def initialize(base_path = nil, assigns_for_first_render = {}, controller = nil)
      initialize_without_gloc(base_path, assigns_for_first_render, controller)
      set_language controller.current_language unless controller.nil?
    end
  end
  
  module Helpers #:nodoc:
    class InstanceTag
      include GLoc
      # Inherits the current language from the template object.
      def current_language
        @template_object.current_language
      end
    end
  end
end

# ==============================================================================

module ActiveRecord #:nodoc:
  class Base #:nodoc:
    include GLoc
  end
  
  class Errors
    include GLoc
    alias :add_without_gloc :add
    # The GLoc version of this method provides two extra features
    # * If <tt>msg</tt> is a string, it will be considered a GLoc string key.
    # * If <tt>msg</tt> is an array, the first element will be considered
    #   the string and the remaining elements will be considered arguments for the
    #   string. Eg. <tt>['Hi %s.','John']</tt>
    def add(attribute, msg= @@default_error_messages[:invalid])
      if msg.is_a?(Array)
        args= msg.clone
        msg= args.shift
        args= nil if args.empty?
      end
      msg= ltry(msg)
      msg= msg % args unless args.nil?
      add_without_gloc(attribute, msg)
    end
    # Inherits the current language from the base record.
    def current_language
      @base.current_language
    end
  end
  
  module Validations #:nodoc:
    module ClassMethods
      # The default Rails version of this function creates an error message and then
      # passes it to ActiveRecord.Errors.
      # The GLoc version of this method, sends an array to ActiveRecord.Errors that will
      # be turned into a string by ActiveRecord.Errors which in turn allows for the message
      # of this validation function to be a GLoc string key.
      def validates_length_of(*attrs)
        # Merge given options with defaults.
        options = {
          :too_long     => ActiveRecord::Errors.default_error_messages[:too_long],
          :too_short    => ActiveRecord::Errors.default_error_messages[:too_short],
          :wrong_length => ActiveRecord::Errors.default_error_messages[:wrong_length]
        }.merge(DEFAULT_VALIDATION_OPTIONS)
        options.update(attrs.pop.symbolize_keys) if attrs.last.is_a?(Hash)

        # Ensure that one and only one range option is specified.
        range_options = ALL_RANGE_OPTIONS & options.keys
        case range_options.size
          when 0
            raise ArgumentError, 'Range unspecified.  Specify the :within, :maximum, :minimum, or :is option.'
          when 1
            # Valid number of options; do nothing.
          else
            raise ArgumentError, 'Too many range options specified.  Choose only one.'
        end

        # Get range option and value.
        option = range_options.first
        option_value = options[range_options.first]

        case option
        when :within, :in
          raise ArgumentError, ":#{option} must be a Range" unless option_value.is_a?(Range)

          too_short = [options[:too_short] , option_value.begin]
          too_long  = [options[:too_long]  , option_value.end  ]

          validates_each(attrs, options) do |record, attr, value|
            if value.nil? or value.split(//).size < option_value.begin
              record.errors.add(attr, too_short)
            elsif value.split(//).size > option_value.end
              record.errors.add(attr, too_long)
            end
          end
        when :is, :minimum, :maximum
          raise ArgumentError, ":#{option} must be a nonnegative Integer" unless option_value.is_a?(Integer) and option_value >= 0

          # Declare different validations per option.
          validity_checks = { :is => "==", :minimum => ">=", :maximum => "<=" }
          message_options = { :is => :wrong_length, :minimum => :too_short, :maximum => :too_long }

          message = [(options[:message] || options[message_options[option]]) , option_value]

          validates_each(attrs, options) do |record, attr, value|
            if value.kind_of?(String)
              record.errors.add(attr, message) unless !value.nil? and value.split(//).size.method(validity_checks[option])[option_value]
            else
              record.errors.add(attr, message) unless !value.nil? and value.size.method(validity_checks[option])[option_value]
            end
          end
        end
      end

      alias_method :validates_size_of, :validates_length_of
    end
  end
end

# ==============================================================================

module ApplicationHelper #:nodoc:
  include GLoc
end
