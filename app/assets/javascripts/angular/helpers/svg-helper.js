//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
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

openprojectApp.factory('SvgHelper', [function() {

  var asSvgNode = function(elementName) {
    var node = document.createElementNS('http://www.w3.org/2000/svg', elementName);
    return jQuery(node);
  }

  var SvgTextHelper = function(top, left, text) {
    this.node = asSvgNode('text');
    this.translate(left, top);
    this.setText(text);
  };

  SvgTextHelper.prototype.toString = function() {
    return "SvgTextHelper";
  };

  SvgTextHelper.prototype.getNode = function() {
    return this.node;
  };

  SvgTextHelper.prototype.setText = function(text) {
    var node = this.node;
    node.empty().append(text);
  }

  SvgTextHelper.prototype.translate = function(left, top) {
    this.node.attr({
      'x': left,
      'y': top
    });
    return this;
  };

  SvgTextHelper.prototype.attr = function() {
    return this.node.attr.apply(this.node, arguments);
  };

  SvgTextHelper.prototype.insertAfter = function() {
    return this.node.insertAfter.apply(this.node, arguments);
  };

  SvgTextHelper.prototype.getBBox = function() {
    // [0] is for the actual, unwrapped DOM node, since jQuery doesn't
    // forward methods limited to SVG elements.
    return this.node[0].getBBox();
  }

  var SvgRectHelper = function(top, left, width, height) {
    this.node = asSvgNode('rect').attr({
      'x': left,
      'y': top,
      'width': width,
      'height': height
    });
  };

  SvgRectHelper.prototype.translate = function(left, top) {
    this.node.attr({
      'x': left,
      'y': top
    });
    return this;
  };

  SvgRectHelper.prototype.toString = function() {
    return "SvgRectHelper";
  };

  var SvgHelper = (function() {

    var SvgHelper = function(node) {
      this.root = asSvgNode('svg').attr({
        'width': 640,
        'height': 480
      });
      jQuery(node).append(this.root);
    };

    SvgHelper.prototype.toString = function() {
      return "SvgHelper";
    };

    SvgHelper.prototype.clear = function() {
      this.root.empty();
    };

    SvgHelper.prototype.setSize = function(width, height) {
      this.root.attr({
        'width': width,
        'height': height,
      });
    };

    SvgHelper.prototype.rect = function(left, top, width, height) {
      var node = new SvgTextHelper(left, top, width, height);
      this.root.append(node.getNode());
      return node;
    };

    SvgHelper.prototype.path = function(direction) {
      var node = asSvgNode('path').attr({
        'd': direction
      });
      this.root.append(node);
      return node;
    };

    SvgHelper.prototype.text = function(left, top, text) {
      var node = new SvgTextHelper(left, top, text);
      this.root.append(node.getNode());
      return node;
    };

    return SvgHelper;
  })();

  return SvgHelper;
}]);
