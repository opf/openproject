class Widget::Table < Widget::Base
  extend Report::InheritedAttribute
  include ReportingHelper

  attr_accessor :debug
  attr_accessor :fields
  attr_accessor :mapping

  def initialize(query)
    raise ArgumentError, "Tables only work on Reports!" unless query.is_a? Report
    super
  end

  # def debug?
  #   !!debug
  # end

  # def show_result(*args)
  #   map :show_result, *args
  # end

  # def show_row(*args)
  #   map :show_row, *args
  # end

  # def label_for(*args)
  #   map :label, *args
  # end

  # def entry_for(*args)
  #   map :entry, *args
  # end

  # def edit_content(*args)
  #   map :edit, *args
  # end

  # def debug_fields(*args)
  #   map :debug_fields, *args
  # end

  # def raw_result(result)
  #   mapped = mapping[:raw_result]
  #   if mapped
  #     mapped.call self, result
  #   else
  #     show_result(result, 0)
  #   end
  # end

  # def show_field(field, *args)
  #   mapped = mapping[:show_field]
  #   if mapped
  #     mapped.call self, field, *args
  #   else
  #     engine::Chainable.mapping_for(field).first.call field, *args
  #   end
  # end

  # def map(to_map, *args)
  #   fail "Table Widget #{self.class} needs a mapping for :#{to_map}" unless mapping[to_map]
  #   mapping[to_map.to_sym].call self, *args
  # end

  # def render_with_options(options = {}, &block)
  #   @fields ||= (options[:fields] || @subject.result.important_fields)
  #   @debug ||= (options[:debug] || false)
  #   @mapping ||= options[:mapping]
  #   fail "mappings need to respond to #call" if mapping.values.any? { |val| not val.respond_to? :call }
  #   canvas = options[:to] ? options[:to] << "\n" : ""
  #   canvas << render(&block)
  # end
  def resolve_table
    if @subject.group_bys.size == 0
      self.class.detailed_table
    elsif @subject.group_bys.size == 1
      self.class.simple_table
    else
      self.class.fancy_table
    end
  end

  def self.detailed_table(klass=nil)
    @@detail_table = klass if klass
    defined?(@@detail_table) ? @@detail_table : fancy_table
  end

  def self.simple_table(klass=nil)
    @@simple_table = klass if klass
    defined?(@@simple_table) ? @@simple_table : fancy_table
  end

  def self.fancy_table(klass=nil)
    @@fancy_table = klass if klass
    @@fancy_table
  end
  fancy_table Widget::Table::ReportTable

  def render
    write("<!-- table start -->")
    if @subject.result.count <= 0
      write(content_tag(:p, l(:label_no_data), :class => "nodata"))
    else
      render_widget(resolve_table, @subject, @options.reverse_merge(:to => @output))
    end
  end
end
