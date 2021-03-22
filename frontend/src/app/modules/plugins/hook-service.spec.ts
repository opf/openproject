//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

/*jshint expr: true*/

import { HookService } from "core-app/modules/plugins/hook-service";

describe('HookService', function() {
  let service:HookService = new HookService();

  var callback:any, invalidCallback:any;
  var validId = 'myValidCallbacks';

  beforeEach(() => {
    service = new HookService();
  });

  var shouldBehaveLikeEmptyResult = function(id:string) {
    it('returns empty results', function() {
      expect(service.call(id).length).toEqual(0);
    });
  };

  var shouldBehaveLikeResultWithElements = function(id:string, count:number) {
    it('returns #count results', function() {
      expect(service.call(id).length).toEqual(count);
    });
  };

  var shouldBehaveLikeCalledCallback = function(id:string) {
    beforeEach(function() {
      service.call(id);
    });

    it('is called', function() {
      expect(callback).toHaveBeenCalled();
    });
  };

  var shouldBehaveLikeUncalledCallback = function(id:string) {
    beforeEach(function() {
      service.call(id);
    });

    it('is not called', function() {
      expect(invalidCallback.called).toBeFalsy();
    });
  };

  describe('register', function() {
    var invalidId = 'myInvalidCallbacks';

    describe('no callback registered', function() {
      shouldBehaveLikeEmptyResult(invalidId);
    });

    describe('valid function callback registered', function() {
      beforeEach(function() {
        callback = jasmine.createSpy('hook');
        service.register('myValidCallbacks', callback);
      });

      shouldBehaveLikeEmptyResult(validId);

      shouldBehaveLikeCalledCallback(validId);
    });
  });

  describe('call', function() {
    describe('function that returns undefined', function() {
      beforeEach(function() {
        callback = jasmine.createSpy('hook');
        service.register('myValidCallbacks', callback);
      });

      shouldBehaveLikeCalledCallback(validId);

      shouldBehaveLikeEmptyResult(validId);
    });

    describe('function that returns something that is not undefined', function() {
      beforeEach(function() {
        callback = jasmine.createSpy('hook').and.returnValue({});

        service.register('myValidCallbacks', callback);
      });

      shouldBehaveLikeCalledCallback(validId);

      shouldBehaveLikeResultWithElements(validId, 1);
    });

    describe('function that returns something that is not undefined', function() {
      beforeEach(function() {
        callback = jasmine.createSpy('hook').and.returnValue({});

        service.register('myValidCallbacks', callback);
      });

      shouldBehaveLikeCalledCallback(validId);

      shouldBehaveLikeResultWithElements(validId, 1);
    });

    describe('function that returns something that is not undefined', function() {
      beforeEach(function() {
        callback = jasmine.createSpy('hook');
        invalidCallback = jasmine.createSpy('invalidHook');

        service.register('myValidCallbacks', callback);

        service.register('myInvalidCallbacks', invalidCallback);
      });

      shouldBehaveLikeCalledCallback(validId);

      shouldBehaveLikeUncalledCallback(validId);
    });

    describe('function that returns something that is not undefined', function() {
      var callback1, callback2;

      beforeEach(function() {
        callback1 = jasmine.createSpy('hook1').and.returnValue({});
        callback2 = jasmine.createSpy('hook1').and.returnValue({});

        service.register('myValidCallbacks', callback1);
        service.register('myValidCallbacks', callback2);
      });

      shouldBehaveLikeResultWithElements(validId, 2);
    });
  });
});
