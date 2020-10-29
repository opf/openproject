require_relative '../lib/svggraph'
require_relative '../lib/SVG/Graph/DataPoint'
require 'minitest/autorun'
require 'minitest/reporters'

reporter_options = { :color => true }
Minitest::Reporters.use! [Minitest::Reporters::DefaultReporter.new(reporter_options)]


class TestSvgGraph < Minitest::Test

  def test_bar_line_and_pie
    fields = %w(Jan Feb Mar);
    data_sales_02 = [12, 45, 21]
    [SVG::Graph::Bar, SVG::Graph::BarHorizontal, SVG::Graph::Line, SVG::Graph::Pie].each do
      |klass|
      graph = klass.new(
        :height => 500,
        :width => 300,
        :fields => fields
      )
      graph.add_data(
        :data => data_sales_02,
        :title => 'Sales 2002'
      )
      out=graph.burn
      assert(out=~/Created with SVG::Graph/)
    end
  end # test_bar_line_and_pie

  def test_pie_100_percent
    fields = %w(Internet TV Newspaper Magazine Radio)
    #data1 = [2, 3, 1, 3, 1]
    #data2 = [0, 2, 1, 5, 4]
    data1 = [0, 3, 0, 0, 0]
    data2 = [0, 6, 0, 0, 0]

    graph = SVG::Graph::Pie.new(
        :height => 500,
        :width => 300,
        :fields => fields,
        :graph_title => "100% pie",
        :show_graph_title => true,
        :show_data_labels => true,
        :show_x_guidelines => true,
        :show_x_title => true,
        :x_title => "Time"
      )
    graph.add_data(
        :data => data1,
        :title => 'data1'
      )

    graph.add_data(
        :data => data2,
        :title => 'data2'
      )
    out = graph.burn
    File.open(File.expand_path("pie_100.svg",__dir__), "w") {|fout|
      fout.print( out )
    }
    assert_match(/TV 100%/, out, "100% text not found in graph")
    assert_match(/circle/, out, "no circle was found in graph")

  end # test_pie_100_percent

end

