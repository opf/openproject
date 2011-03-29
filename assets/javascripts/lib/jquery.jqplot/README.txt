Title: jqPlot Readme

Pure JavaScript plotting plugin for jQuery.

Copyright (c) 2009 Chris Leonello
This software is licensed under the GPL version 2.0 and MIT licenses.

To learn how to use jqPlot, start with the Basic Unsage Instructions below.  Then read the
usage.txt and jqPlotOptions.txt files included with the distribution.

The jqPlot home page is at <http://www.jqplot.com/>.

Downloads can be found at <http://bitbucket.org/cleonello/jqplot/downloads/>.

The mailing list is at <http://groups.google.com/group/jqplot-users>.

Examples and unit tests are at <http://www.jqplot.com/tests/>.

Documentation is at <http://www.jqplot.com/docs/>.

The project page and source code are at <http://www.bitbucket.org/cleonello/jqplot/>.

Bugs, issues, feature requests: <http://www.bitbucket.org/cleonello/jqplot/issues/>.

Basic Usage Instructions:

jqPlot requires jQuery (tested with 1.3.2 or better). jQuery 1.3.2 is included in 
the distribution.  To use jqPlot include jQuery, the jqPlot jQuery plugin, the jqPlot css file and 
optionally the excanvas script for IE support in your web page...

> <!--[if IE]><script language="javascript" type="text/javascript" src="excanvas.js"></script><![endif]-->
> <script language="javascript" type="text/javascript" src="jquery-1.3.2.min.js"></script>
> <script language="javascript" type="text/javascript" src="jquery.jqplot.min.js"></script>
> <link rel="stylesheet" type="text/css" href="jquery.jqplot.css" />

For usage instructions, see <jqPlot Usage> in usage.txt.  For available options, see
<jqPlot Options> in jqPlotOptions.txt.

Building from source:

To build a distribution from source you need to have ant <http://ant.apache.org> 
installed.  There are 6 targets: clean, dist, min, tests, docs and all.  Use

> ant -p

to get a description of the various build targets. 
