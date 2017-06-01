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

(function(Color) {
  var examples = [
    {name: "pjBlack", hex:  "#000000"},
    {name: "pjRed", hex:  "#FF0013"},
    {name: "pjYellow", hex:   "#FEFE56"},
    {name: "pjLime", hex:   "#82FFA1"},
    {name: "pjAqua", hex:   "#C0DDFC"},
    {name: "pjBlue", hex:   "#1E16F4"},
    {name: "pjFuchsia", hex:  "#FF7FF7"},
    {name: "pjWhite", hex:  "#FFFFFF"},
    {name: "pjMaroon", hex:   "#850005"},
    {name: "pjGreen", hex:  "#008025"},
    {name: "pjOlive", hex:  "#7F8027"},
    {name: "pjNavy", hex:   "#09067A"},
    {name: "pjPurple", hex:   "#86007B"},
    {name: "pjTeal", hex:   "#008180"},
    {name: "pjGray", hex:   "#808080"},
    {name: "pjSilver", hex:   "#BFBFBF"}
  ];

  Factory.define('Color', Color)
    .sequence('id')
    .sequence('name', function (i) {return given[i] || "Color No. " + i;})
    .sequence('position')
    .sequence('hexcode', function (i) {return given[i] || "#000000";});
})($injector.get('Color'));
