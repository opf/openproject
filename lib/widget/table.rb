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
      str = render_widget(resolve_table, @subject, @options.reverse_merge(:to => @output))
      @cache_output.write(str.html_safe) if @cache_output
    end
  end
end
