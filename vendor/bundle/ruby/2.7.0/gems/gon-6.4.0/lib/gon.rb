require 'request_store'
require 'action_view'
require 'action_controller'
require 'multi_json'

require 'gon/base'
require 'gon/env_finder'
require 'gon/global'
require 'gon/watch'
require 'gon/request'
require 'gon/helpers'
require 'gon/escaper'
require 'gon/rabl'
require 'gon/jbuilder'
require 'gon/jbuilder/parser'
require 'gon/json_dumper'

# NOTE : ActionDispatch::Request#uuid appears only in Rails 3.2.1
unless ActionDispatch::Request.public_instance_methods.include?(:uuid)
  require 'gon/compatibility/old_rails'
end

require 'gon/spec_helpers'

class Gon
  class << self

    def global
      Gon::Global
    end

    def watch
      Gon::Watch
    end

    def method_missing(method, *args, &block)
      if method.to_s =~ /=$/
        if public_method_name?(method)
          raise "You can't use Gon public methods for storing data: #{method}"
        end
        if self == Gon && !current_gon
          raise 'Assign request-specific gon variables only through `gon` helper, not through Gon constant'
        end

        set_variable(method.to_s.delete('='), args[0])
      else
        get_variable(method.to_s)
      end
    end

    def get_variable(name)
      current_gon.gon[name]
    end

    def set_variable(name, value)
      current_gon.gon[name] = value
    end

    def merge_variable(name, value)
      old_value = all_variables[name]
      if value.is_a?(Hash) && old_value.is_a?(Hash)
        value = old_value.deep_merge(value)
      end
      set_variable(name, value)
    end

    def push(data = {}, merge = false)
      raise 'Object must have each_pair method' unless data.respond_to? :each_pair

      if merge
        data.each_pair do |name, value|
          merge_variable(name.to_s, value)
        end
      else
        data.each_pair do |name, value|
          set_variable(name.to_s, value)
        end
      end
    end

    def all_variables
      current_gon ? current_gon.gon : {}
    end

    def clear
      current_gon.clear if current_gon
    end

    def rabl(*args)
      data, options = Gon::Rabl.handler(args)
      store_builder_data 'rabl', data, options
    end

    def jbuilder(*args)
      ensure_template_handler_is_defined
      data, options = Gon::Jbuilder.handler(args)
      store_builder_data 'jbuilder', data, options
    end

    def inspect
      'Gon'
    end

    private

    def current_gon
      RequestStore.store[:gon]
    end

    def store_builder_data(builder, data, options)
      if options[:as]
        set_variable(options[:as].to_s, data)
      elsif data.is_a? Hash
        data.each { |k, v| set_variable(k, v) }
      else
        set_variable(builder, data)
      end
    end

    def public_method_name?(method)
      public_methods.include?(method.to_s[0..-2].to_sym)
    end

    # JbuilderTemplate will not be defined if jbuilder is required
    # before gon. By loading jbuilder again, JbuilderTemplate will
    # now be defined
    def ensure_template_handler_is_defined
      load 'jbuilder.rb' unless defined?(JbuilderTemplate)
    end

  end
end
