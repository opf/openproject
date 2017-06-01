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

/*jshint expr: true*/

describe('Timeline', function() {

  var model;

  beforeEach(angular.mock.module('openproject.timelines.models', 'openproject.uiComponents'));
  beforeEach(inject(function(Timeline) {
    model = Timeline;
  }));

  it('should exist', function() {
    expect(model).to.exist;
  });

  it('should not create a timeline object without configuration options', function() {
    expect(function() {
      model.create(42);
    }).to.throw('No configuration options given');
  });

  it('should not create a timeline object without id', function() {
    expect(function() {
      model.create(null, {});
    }).to.throw('No timelines id given');
  });

  it('should create a timeline object', function () {
    expect(model.instances).to.have.length(0);

    var timeline = model.create(42, {
      project_id: 1
    });

    expect(model.instances).to.have.length(1);
    expect(timeline).to.be.a('object');
  });

});
