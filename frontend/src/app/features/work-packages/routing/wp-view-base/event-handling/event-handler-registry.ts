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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { EventEmitter, InjectionToken, Injector } from '@angular/core';
import { delegate } from '@knowledgecode/delegate';

export type EventType = keyof HTMLElementEventMap;

export interface WorkPackageViewEventHandler<T> {
  /** Event name to register * */
  EVENT:EventType|EventType[];

  /** Event context CSS selector */
  SELECTOR:string;

  /** Event callback handler */
  handleEvent(view:T, evt:Event):void;

  /** Event scope method */
  eventScope(view:T):HTMLElement;
}

export interface WorkPackageViewOutputs {
  // On selection updated
  selectionChanged:EventEmitter<string[]>;
  // On row (double) clicked
  itemClicked:EventEmitter<{ workPackageId:string, double:boolean }>;
  // On work package link / details icon clicked
  stateLinkClicked:EventEmitter<{ workPackageId:string, requestedState:string }>;
}

export const WorkPackageViewHandlerToken = new InjectionToken<WorkPackageViewEventHandler<any>>('CardEventHandler');

/**
 * Abstract view handler registry for globally handling arbitrary event on the
 * view container. Used e.g., for table to register single event callbacks for the entirety
 * of the table.
 */
export abstract class WorkPackageViewHandlerRegistry<T> {
  constructor(public readonly injector:Injector) {
  }

  protected abstract eventHandlers:((view:T) => WorkPackageViewEventHandler<T>)[];

  attachTo(viewRef:T) {
    this.eventHandlers.map((factory) => {
      const handler = factory(viewRef);
      const target = handler.eventScope(viewRef);
      const types = Array.isArray(handler.EVENT) ? handler.EVENT : [handler.EVENT];

      types.forEach((type) => {
        delegate(target).on(type, handler.SELECTOR, (evt) => {
          handler.handleEvent(viewRef, evt.originalEvent);
        });
      });

      return handler;
    });
  }
}
