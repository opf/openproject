class Widget::Table < Widget::Base
  extend Report::InheritedAttribute
  include ReportingHelper # FIXME ugs in the ugly. have to think of something else for mapping stuff

  inherited_attribute :debug, :default => false

  def initialize(query, options = {})
    raise ArgumentError, "Tables only work on Reports!" unless query.is_a? Report
    super(query)
  end

  def debug?
    !!debug
  end

  def render_with_options(options = {}, &block)
    canvas = options[:to] ? options[:to] << "\n" : ""
    canvas << render(&block)
  end

  def table_widget
    if @query.depth_of(:row) == 0
      @query.row(:singleton_value)
    elsif @query.depth_of(:column) == 0
      @query.column(:singleton_value)
    end
    Widget::Table::ReportTable
  end

  def render
    content_tag :div, :id => "result-table" do
      if @query.group_bys.empty? || @query.result.count <= 0
        content_tag :p, l(:label_no_data), :class => "nodata"
      else
        render_widget table_widget, @query, { :debug => debug? }
      end
    end
  end

end
