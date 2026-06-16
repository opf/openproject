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

import { TestBed } from '@angular/core/testing';
import { Injectable, OnDestroy, inject } from '@angular/core';
import { action, props } from 'ts-action';
import { ActionsService } from 'core-app/core/state/actions/actions.service';
import { EffectCallback, EffectHandler } from './effect-handler.decorator';

const pingAction = action('[Test] ping', props<{ value:number }>());

@Injectable()
@EffectHandler
class TestEffectService {
  readonly actions$ = inject(ActionsService);

  readonly received:number[] = [];

  @EffectCallback(pingAction)
  private onPing(payload:ReturnType<typeof pingAction>):void {
    this.received.push(payload.value);
  }
}

describe('EffectHandler decorator', () => {
  let actions:ActionsService;

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [TestEffectService] });
    actions = TestBed.inject(ActionsService);
  });

  it('instantiates without the inherited-injectable deprecation warning', () => {
    vi.spyOn(console, 'warn');

    expect(TestBed.inject(TestEffectService)).toBeTruthy();
    expect(console.warn).not.toHaveBeenCalledWith(
      expect.stringContaining('inherits its @Injectable decorator'),
    );
  });

  it('binds @EffectCallback handlers to the actions stream', () => {
    const service = TestBed.inject(TestEffectService);

    actions.dispatch(pingAction({ value: 7 }));

    expect(service.received).toEqual([7]);
  });

  it('stops handling effects after ngOnDestroy', () => {
    const service = TestBed.inject(TestEffectService);
    (service as unknown as OnDestroy).ngOnDestroy();

    actions.dispatch(pingAction({ value: 9 }));

    expect(service.received).toEqual([]);
  });
});
