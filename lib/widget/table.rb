class Widget::Table < Widget::Base
  extend Report::InheritedAttribute
  include ReportingHelper # FIXME ugs in the ugly. have to think of something else for mapping stuff

  inherited_attribute :debug, :default => false

  def initialize(query, options = {})
    raise ArgumentError, "Tables only work on Reports!" unless query.is_a? Report
    super(query)
    debug = options[:debug] || false
    mapping = options[:mapping] || {}
  end

  def debug?
    !!debug
  end

  def render_with_options(options = {}, &block)
    if canvas = options[:to]
      canvas << "\n" << render(&block)
    else
      render(&block)
    end
  end

  def render
    if @query.depth_of(:column) + @query.depth_of(:row) == 0
      widget = Widget::Table::SimpleTable
    else
      if @query.depth_of(:row) == 0
        @query.row(:singleton_value)
      elsif @query.depth_of(:column) == 0
        @query.column(:singleton_value)
      end
    end
    widget = Widget::Table::ReportTable
    content_tag :div, :id => "result-table" do
      if @query.result.count > 0
        render_widget widget, @query, { :debug => debug? }
      else
        content_tag :p, l(:label_no_data), :class => "nodata"
      end
    end
  end

end
