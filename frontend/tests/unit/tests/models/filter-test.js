//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

/*jshint expr: true*/

describe('Filter', function() {

  var Filter;

  beforeEach(module('openproject.models'));
  beforeEach(inject(function(_Filter_) {
    Filter = _Filter_;
  }));

  it('should exist', function() {
    expect(Filter).to.exist;
  });

  it('should be a constructor function', function() {
    expect(new Filter()).to.exist;
    expect(new Filter()).to.be.an('object');
  });

  it('should be serializable to params', function() {
    var filter = Factory.build('Filter');

    var params = filter.toParams();

    expect(params).to.have.property('op[type_id]')
                  .and.equal('~');
    expect(params).to.have.property('v[type_id][]')
                  .and.contain('Bug');

  });

  describe('when it is a single input filter', function() {
    var filter, textValue;

    beforeEach(function(){
      filter = Factory.build('Filter', {name: 'subject', values: []});
    });

    describe('and the text value is set', function() {
      beforeEach(function() {
        textValue = 'abc';
        filter.textValue = textValue;
      });

      it('is considered to be configured', function() {
        expect(filter.isConfigured()).to.be.true;
      });

      it('should serialize the text value', function() {
        expect(filter.getValuesAsArray()).to.eql([textValue]);
      });
    });
  });

});
