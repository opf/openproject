//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
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
// See COPYRIGHT and LICENSE files for more details.
//++

/* jshint expr: true */

import { HookService } from 'core-app/features/plugins/hook-service';

describe('HookService', () => {
  let service:HookService = new HookService();

  let callback:any; let
    invalidCallback:any;
  const validId = 'myValidCallbacks';

  beforeEach(() => {
    service = new HookService();
  });

  const shouldBehaveLikeEmptyResult = function (id:string) {
    it('returns empty results', () => {
      expect(service.call(id).length).toEqual(0);
    });
  };

  const shouldBehaveLikeResultWithElements = function (id:string, count:number) {
    it('returns #count results', () => {
      expect(service.call(id).length).toEqual(count);
    });
  };

  const shouldBehaveLikeCalledCallback = function (id:string) {
    beforeEach(() => {
      service.call(id);
    });

    it('is called', () => {
      expect(callback).toHaveBeenCalled();
    });
  };

  const shouldBehaveLikeUncalledCallback = function (id:string) {
    beforeEach(() => {
      service.call(id);
    });

    it('is not called', () => {
      expect(invalidCallback.called).toBeFalsy();
    });
  };

  describe('register', () => {
    const invalidId = 'myInvalidCallbacks';

    describe('no callback registered', () => {
      shouldBehaveLikeEmptyResult(invalidId);
    });

    describe('valid function callback registered', () => {
      beforeEach(() => {
        callback = jasmine.createSpy('hook');
        service.register('myValidCallbacks', callback);
      });

      shouldBehaveLikeEmptyResult(validId);

      shouldBehaveLikeCalledCallback(validId);
    });
  });

  describe('call', () => {
    describe('function that returns undefined', () => {
      beforeEach(() => {
        callback = jasmine.createSpy('hook');
        service.register('myValidCallbacks', callback);
      });

      shouldBehaveLikeCalledCallback(validId);

      shouldBehaveLikeEmptyResult(validId);
    });

    describe('function that returns something that is not undefined', () => {
      beforeEach(() => {
        callback = jasmine.createSpy('hook').and.returnValue({});

        service.register('myValidCallbacks', callback);
      });

      shouldBehaveLikeCalledCallback(validId);

      shouldBehaveLikeResultWithElements(validId, 1);
    });

    describe('function that returns something that is not undefined', () => {
      beforeEach(() => {
        callback = jasmine.createSpy('hook').and.returnValue({});

        service.register('myValidCallbacks', callback);
      });

      shouldBehaveLikeCalledCallback(validId);

      shouldBehaveLikeResultWithElements(validId, 1);
    });

    describe('function that returns something that is not undefined', () => {
      beforeEach(() => {
        callback = jasmine.createSpy('hook');
        invalidCallback = jasmine.createSpy('invalidHook');

        service.register('myValidCallbacks', callback);

        service.register('myInvalidCallbacks', invalidCallback);
      });

      shouldBehaveLikeCalledCallback(validId);

      shouldBehaveLikeUncalledCallback(validId);
    });

    describe('function that returns something that is not undefined', () => {
      let callback1; let
        callback2;

      beforeEach(() => {
        callback1 = jasmine.createSpy('hook1').and.returnValue({});
        callback2 = jasmine.createSpy('hook1').and.returnValue({});

        service.register('myValidCallbacks', callback1);
        service.register('myValidCallbacks', callback2);
      });

      shouldBehaveLikeResultWithElements(validId, 2);
    });
  });
});
