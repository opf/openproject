SVG::Graph
============

Description
-----------
This repo is the continuation of the original [SVG::Graph library](http://www.germane-software.com/software/SVG/SVG::Graph/) by Sean Russell. I'd like to thank Claudio Bustos for giving me permissions to continue publishing the gem under it's original name: [svg-graph](https://rubygems.org/gems/svg-graph)

[Changelog](../master/History.txt)

I'm maintaing in my free time, so I can't promise on any deadlines. Please notify me (via github messages or on the Issues section) if you find any bug.

Contribute
-----
Pull requests are very welcome :-)

Usage
-----

For a complete list of configuration options please have a look at the source - most important [Graph.rb](../master/lib/SVG/Graph/Graph.rb), also checkout the subclasses (Pie, Bar, etc.) as they might provide additional options.

You can require everything at once
```ruby
require 'svggraph'
```
or only the individual parts you need
```ruby
require 'SVG/Graph/Bar'
require 'SVG/Graph/Line'
...
```

In the following some examples to get you up to speed.

### Bar
```ruby
require 'SVG/Graph/Bar'

x_axis = ['1-10', '10-30', '30-50', '50-70', 'older']

options = {
  :width             => 640,
  :height            => 300,
  :stack             => :side,  # the stack option is valid for Bar graphs only
  :fields            => x_axis,
  :graph_title       => "kg per head and year chocolate consumption",
  :show_graph_title  => true,
  :show_x_title      => true,
  :x_title           => 'Age in years',
  :show_y_title      => true,
  :y_title           => 'kg/year',
  :y_title_location  => :end,
  :no_css            => true
}

male_data   = [2, 4, 6, 4, 2]
female_data = [1, 5, 4, 5, 2.7]

g = SVG::Graph::Bar.new(options)

g.add_data( {
    :data => female_data,
    :title => "Female"
  })
g.add_data( {
    :data => male_data,
    :title => "Male"
  })

# graph.burn            # this returns a full valid xml document containing the graph
# graph.burn_svg_only   # this only returns the <svg>...</svg> node
File.open('bar.svg', 'w') {|f| f.write(g.burn_svg_only)}
```
![example bar graph](https://cdn.rawgit.com/lumean/svg-graph2/master/examples/bar.svg)

### BarHorizontal

![example bar_horizontal graph](https://cdn.rawgit.com/lumean/svg-graph2/master/examples/bar_horizontal.svg)

### ErrBar

![example err_bar graph](https://cdn.rawgit.com/lumean/svg-graph2/master/examples/err_bar.svg)

### Line

![example line graph](https://cdn.rawgit.com/lumean/svg-graph2/master/examples/line.svg)

### Pie

![example pie graph](https://cdn.rawgit.com/lumean/svg-graph2/master/examples/pie.svg)

### Plot

![example plot graph](https://cdn.rawgit.com/lumean/svg-graph2/master/examples/plot.svg)

### Schedule

![example schedule graph](https://cdn.rawgit.com/lumean/svg-graph2/master/examples/schedule.svg)

### TimeSeries

![example timeseries graph](https://cdn.rawgit.com/lumean/svg-graph2/master/examples/timeseries.svg)

### C3js

Source: [C3js.rb](../master/examples/c3js.rb)

[Link to Preview](https://cdn.rawgit.com/lumean/svg-graph2/master/examples/c3js.html)

<iframe src="https://cdn.rawgit.com/lumean/svg-graph2/master/examples/c3js.html" width="600px"> </iframe>

Also have a look at the original [SVG::Graph web page](http://www.germane-software.com/software/SVG/SVG::Graph/), but note that this repository has already added some additional functionality, not available with the original.

Build
-----

* Build gem:
 *  gem build svg-graph.gemspec
* Install:
 *  gem install svg-graph-\<version>.gem
