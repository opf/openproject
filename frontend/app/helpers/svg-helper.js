//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2017 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See doc/COPYRIGHT.rdoc for more details.
//++

// ╭───────────────────────────────────────────────────────────────╮
// │  _____ _                _ _                                   │
// │ |_   _(_)_ __ ___   ___| (_)_ __   ___  ___                   │
// │   | | | | '_ ` _ \ / _ \ | | '_ \ / _ \/ __|                  │
// │   | | | | | | | | |  __/ | | | | |  __/\__ \                  │
// │   |_| |_|_| |_| |_|\___|_|_|_| |_|\___||___/                  │
// ├───────────────────────────────────────────────────────────────┤
// │ Javascript library that fetches and plots timelines for the   │
// │ OpenProject timelines module.                                 │
// ╰───────────────────────────────────────────────────────────────╯

module.exports = function() {

  var SvgHelper = function(node) {
    this.root = this.provideNode('svg').attr({
      'width': 640,
      'height': 480
    });
    jQuery(node).append(this.root);
  };

  SvgHelper.prototype.toString = function() {
    return "SvgHelper";
  };

  SvgHelper.prototype.provideNode = function(elementName) {
    return document.createElementNS(
      'http://www.w3.org/2000/svg',
      elementName
    );
  };

  SvgHelper.prototype.clear = function() {
    var node = this.root;
    while (node.hasChildNodes() ){
      node.removeChild(node.lastChild);
    }
    return this;
  };

  SvgHelper.prototype.setSize = function(w, h) {
    this.root.attr({
      'width': w,
      'height': h,
    });
  };

  SvgHelper.prototype.rect = function(x, y, w, h, r) {
    var node = this.provideNode('rect').attr({
      'x': x,
      'y': y,
      'width': w,
      'height': h
    });

    if (r) {
      node.round(r);
    }

    this.root.appendChild(node);
    return node;
  };

  SvgHelper.prototype.path = function(direction) {
    var node = this.provideNode('path').attr({
      'd': direction
    });
    this.root.appendChild(node);
    return node;
  };

  SvgHelper.prototype.text = function(x, y, text) {
    var node = this.provideNode('text');
    node.translate(x, y);
    node.textContent = text;

    this.root.appendChild(node);
    return node;
  };

  SvgHelper.prototype.gradient = function(id, stops) {
    var svg = this.root;
    var svgNS = svg.namespaceURI;
    var gradient  = document.createElementNS(svgNS, 'linearGradient');
    gradient.setAttribute('id', id);
    for (var i=0; i < stops.length; i++){
      var attrs = stops[i];
      var stop = document.createElementNS(svgNS, 'stop');
      for (var attr in attrs) {
        if (attrs.hasOwnProperty(attr)) stop.setAttribute(attr, attrs[attr]);
      }
      gradient.appendChild(stop);
    }

    var defs = svg.querySelector('defs') || svg.insertBefore(document.createElementNS(svgNS, 'defs'), svg.firstChild);
    return defs.appendChild(gradient);
  };

  jQuery.each([SVGSVGElement, SVGRectElement, SVGPathElement,
      SVGTextElement], function (i, klass) {
    klass.prototype.attr = function(attributeHash) {
      for (var key in attributeHash) {
        if (attributeHash.hasOwnProperty(key)) {
          this.setAttribute(key, attributeHash[key]);
        }
      }
      // allow chaining.
      return this;
    };
  });

  jQuery.each([SVGRectElement, SVGTextElement], function (i, klass) {
    klass.prototype.translate = function(x, y) {
      return this.attr({
        'x': x,
        'y': y
      });
    };

    klass.prototype.insertAfter = function(node) {
      this.parentNode.insertBefore(node, this.nextSibling);
    };
  });

  SVGRectElement.prototype.round = function(r) {
    this.attr({
      'rx': r,
      'ry': r
    });
  };

  SVGRectElement.prototype.hover = function(f_in, f_out) {
    this.addEventListener("mouseover", f_in);
    this.addEventListener("mouseout", f_out);
  };

  SVGRectElement.prototype.unhover = function() {
    // TODO (not sure if we even need this)
  };

  SVGRectElement.prototype.click = function(cb) {
    this.addEventListener("click", cb);
  };

  SVGPathElement.prototype.transform = function(transform) {
    return this.attr({'transform': transform});
  };


  return SvgHelper;
};
