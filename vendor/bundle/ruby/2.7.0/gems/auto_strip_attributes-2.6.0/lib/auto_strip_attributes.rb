require "auto_strip_attributes/version"

module AutoStripAttributes
  def auto_strip_attributes(*attributes)
    options = AutoStripAttributes::Config.filters_enabled
    if attributes.last.is_a?(Hash)
      options = options.merge(attributes.pop)
    end

    # option `:virtual` is needed because we want to guarantee that
    # getter/setter methods for an attribute will _not_ be invoked by default
    virtual = options.delete(:virtual)

    attributes.each do |attribute|
      before_validation(options) do |record|
        if virtual
          value = record.public_send(attribute)
        else
          value = record[attribute]
        end
        AutoStripAttributes::Config.filters_order.each do |filter_name|
          next if !options[filter_name]
          filter = lambda { |original| AutoStripAttributes::Config.filters[filter_name].call(original, options[filter_name]) }
          value = if value.respond_to?(:is_a?) && value.is_a?(Array)
            array = value.map { |item| filter.call(item) }.compact
            options[:nullify_array] && array.empty? ? nil : array
          else
            filter.call(value)
          end
          if virtual
            record.public_send("#{attribute}=", value)
          else
            record[attribute] = value
          end
        end
      end
    end
  end
end

class AutoStripAttributes::Config
  class << self
    attr_accessor :filters
    attr_accessor :filters_enabled
    attr_accessor :filters_order
  end

  def self.setup(clear_previous: false, defaults: true, &block)
    @filters, @filters_enabled, @filters_order = {}, {}, [] if clear_previous

    @filters ||= {}
    @filters_enabled ||= {}
    @filters_order ||= []

    if defaults
      set_filter(convert_non_breaking_spaces: false) do |value|
        value.respond_to?(:gsub) ? value.gsub("\u00A0", " ") : value
      end
      set_filter(strip: true) do |value|
        value.respond_to?(:strip) ? value.strip : value
      end
      set_filter(nullify: true) do |value|
        # We check for blank? and empty? because rails uses empty? inside blank?
        # e.g. MiniTest::Mock.new() only responds to .blank? but not empty?, check tests for more info
        # Basically same as value.blank? ? nil : value
        (value.respond_to?(:'blank?') and value.respond_to?(:'empty?') and value.blank?) ? nil : value
      end
      set_filter(nullify_array: true) {|value| value}
      set_filter(squish: false) do |value|
        value = value.respond_to?(:gsub) ? value.gsub(/[[:space:]]+/, ' ') : value
        value.respond_to?(:strip) ? value.strip : value
      end
      set_filter(delete_whitespaces: false) do |value|
        value.respond_to?(:delete) ? value.delete(" \t") : value
      end
    end

    instance_eval(&block) if block_given?
  end

  def self.set_filter(filter, &block)
    if filter.is_a?(Hash)
      filter_name = filter.keys.first
      filter_enabled = filter.values.first
    else
      filter_name = filter
      filter_enabled = false
    end
    @filters[filter_name] = block
    @filters_enabled[filter_name] = filter_enabled
    # in case filter is redefined, we probably don't want to change the order
    @filters_order << filter_name if !@filters_order.include?(filter_name)
  end
end

#ActiveRecord::Base.send(:extend, AutoStripAttributes) if defined? ActiveRecord
ActiveSupport.on_load(:active_record) do
  extend AutoStripAttributes
end

AutoStripAttributes::Config.setup
