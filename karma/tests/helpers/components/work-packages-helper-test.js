//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe('Work packages helper', function() {
  var WorkPackagesHelper;

  beforeEach(module('openproject.helpers'));
  beforeEach(inject(function(_WorkPackagesHelper_) {
    WorkPackagesHelper = _WorkPackagesHelper_;
  }));

  describe('getRowObjectContent', function() {
    var getRowObjectContent;

    beforeEach(function() {
      getRowObjectContent = WorkPackagesHelper.getRowObjectContent;
    });

    describe('with an object', function() {
      it('should return object name', function() {
        var object = {
          assignee: { name: 'user1', subject: 'not this' }
        };

        expect(getRowObjectContent(object, 'assignee')).to.equal('user1');
      });

      it('should return object subject', function() {
        var object = {
          assignee: { subject: 'subject1' }
        };

        expect(getRowObjectContent(object, 'assignee')).to.equal('subject1');
      });

      it('should handle null and emtpy objects', function() {
        expect(getRowObjectContent({ assignee: {}}, 'assignee')).to.equal('');
        expect(getRowObjectContent({}, 'assignee')).to.equal('');
      });
    });

    describe('with a number', function() {
      it('should return the number', function() {
        expect(getRowObjectContent({ number_field: 10 }, 'number_field')).to.equal(10);
      });

      it('should handle missing data', function() {
        expect(getRowObjectContent({}, 'number_field')).to.equal('');
      });
    });

    describe('with a custom field', function() {
      it('should return type string custom field', function() {
        var object = {
          custom_values: [ { custom_field_id: 1, value: 'custom field string'} ]
        }

        expect(getRowObjectContent(object, 'cf_1')).to.equal('custom field string');
      });

      it('should return type object custom field', function() {
        var object = {
          custom_values: [ { custom_field_id: 1, value: { name: 'name1' }} ]
        }

        expect(getRowObjectContent(object, 'cf_1')).to.equal('name1');
      });

      it('should handle missing data', function() {
        var object = {
          custom_values: [ { custom_field_id: 1, value: 'whatever'} ]
        }

        expect(getRowObjectContent(object, 'cf_2')).to.equal('');
        expect(getRowObjectContent({}, 'cf_1')).to.equal('');
      });

    });

  });
});
