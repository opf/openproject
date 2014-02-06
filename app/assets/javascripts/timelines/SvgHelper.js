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

  jQuery.each([SVGSVGElement, SVGRectElement, SVGPathElement,
      SVGTextElement], function (i, klass) {
    klass.prototype.attr = function(attributeHash) {
      for (key in attributeHash) {
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
  });

  SVGTextElement.prototype.insertAfter = function() {
    // TODO
  }

  SVGRectElement.prototype.hover = function() {
    // TODO
  }

  SVGRectElement.prototype.unhover = function() {
    // TODO
  }

  SVGRectElement.prototype.click = function() {
    // TODO
  }

  SVGPathElement.prototype.transform = function(transform) {
    return this.attr({'transform': transform});
  };

  var SvgHelper = (function() {

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

    SvgHelper.prototype.rect = function(x, y, w, h) {
      var node = this.provideNode('rect').attr({
        'x': x,
        'y': y,
        'width': w,
        'height': h,
      });
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

    return SvgHelper;
  })();

  return SvgHelper;
}]);
