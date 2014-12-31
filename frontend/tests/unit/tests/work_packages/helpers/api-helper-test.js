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

describe('API helper', function() {
  var ApiHelper;

  beforeEach(module('openproject.helpers',
                    'openproject.workPackages.services'));
  beforeEach(inject(function(_ApiHelper_) {
    ApiHelper = _ApiHelper_;
  }));

  function createErrorObject(status, statusText, responseText) {
    var error = {};

    error.status = status;
    error.statusText = statusText;
    error.responseText = responseText;

    return error;
  }

  describe('500', function() {
    var error = createErrorObject(500, "Internal Server Error");

    it('should return status text', function() {
      expect(ApiHelper.getErrorMessage(error)).to.eq(error.statusText);
    });
  });

  describe('other codes', function() {
    function createApiErrorObject(errorIdentifier, message, multiple) {
      var apiError = {};

      apiError._type = 'Error';
      apiError.errorIdentifier = (multiple) ? 'urn:openproject-org:api:v3:errors:MultipleErrors' : errorIdentifier;
      apiError.message = message;

      if (multiple) {
        apiError._embedded = { errors: [] };

        for (var x=0; x < 2; x++) {
          apiError._embedded.errors.push(createApiErrorObject(errorIdentifier, message));
        }
      }

      return apiError;
    }

    describe('single error', function() {
      var apiError = createApiErrorObject('NotFound', 'Not found.');
      var error = createErrorObject(404, null, JSON.stringify(apiError));
      var expectedResult = 'Not found.';

      it('should return api error message', function() {
        expect(ApiHelper.getErrorMessage(error)).to.eq(expectedResult);
      });
    });

    describe('multiple errors', function() {
      var errorMessage = 'This is an error message.';
      var apiError = createApiErrorObject('PropertyIsReadOnly', errorMessage, true);
      var error = createErrorObject(404, null, JSON.stringify(apiError));

      it('should return concatenated api error messages', function() {
        var messages = [];
        var expectedResult = errorMessage + ' ' + errorMessage;

        expect(ApiHelper.getErrorMessage(error)).to.eq(expectedResult);
      });
    });
  });
});
