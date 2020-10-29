= SVG::Graph

http://www.germane-software.com/software/SVG/SVG::Graph/

== AUTHOR

Sean E. Russell <serATgermaneHYPHENsoftwareDOTcom>
Copyright 2004 Sean E. Russell
This software is available under the Ruby license[LICENSE.txt]

== DEVELOPERS

* Claudio Bustos <clbustos_AT_gmail_DOT_com
* Liehann Loots <liehhanl_AT_gmail_DOT_com
* Piergiuliano Bossi <pgbossi_AT_gmail_DOT_com

== DESCRIPTION:

This is a  revision of the [SVG::Graph library](http://www.germane-software.com/software/SVG/SVG::Graph/) by Sean Russell with touch-ups to make it run on Ruby 1.9.x and be gem-installable. See History.txt for other changes

SVG:::Graph is a pure Ruby library for generating charts, which are a type of graph where the values of one axis are not scalar. SVG::Graph has a verry similar API to the Perl library SVG::TT::Graph, and the resulting charts also look the same. This isn't surprising, because SVG::Graph started as a loose port of SVG::TT::Graph, although the internal code no longer resembles the Perl original at all.

== FEATURES

* Tested for Ruby versions 1.8.6, 1.8.7 and 1.9.*

We are not sure that all the parts of the original SVG library work as expected under 1.9.x too. Please notify via github messages or on the Issues section if you find any bug.

== LICENSE:

(The Ruby Licence)

SVG::Graph is copyrighted free software by Sean Russell <ser@germane-software.com>.
You can redistribute it and/or modify it under either the terms of the GPL
(see GPL.txt file), or the conditions below:

  1. You may make and give away verbatim copies of the source form of the
     software without restriction, provided that you duplicate all of the
     original copyright notices and associated disclaimers.

  2. You may modify your copy of the software in any way, provided that
     you do at least ONE of the following:

       a) place your modifications in the Public Domain or otherwise
          make them Freely Available, such as by posting said
	  modifications to Usenet or an equivalent medium, or by allowing
	  the author to include your modifications in the software.

       b) use the modified software only within your corporation or
          organization.

       c) rename any non-standard executables so the names do not conflict
	  with standard executables, which must also be provided.

       d) make other distribution arrangements with the author.

  3. You may distribute the software in object code or executable
     form, provided that you do at least ONE of the following:

       a) distribute the executables and library files of the software,
	  together with instructions (in the manual page or equivalent)
	  on where to get the original distribution.

       b) accompany the distribution with the machine-readable source of
	  the software.

       c) give non-standard executables non-standard names, with
          instructions on where to get the original software distribution.

       d) make other distribution arrangements with the author.

  4. You may modify and include the part of the software into any other
     software (possibly commercial).  But some files in the distribution
     are not written by the author, so that they are not under this terms.

     They are gc.c(partly), utils.c(partly), regex.[ch], st.[ch] and some
     files under the ./missing directory.  See each file for the copying
     condition.

  5. The scripts and library files supplied as input to or produced as 
     output from the software do not automatically fall under the
     copyright of the software, but belong to whomever generated them, 
     and may be sold commercially, and may be aggregated with this
     software.

  6. THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
     IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
     WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
     PURPOSE.
