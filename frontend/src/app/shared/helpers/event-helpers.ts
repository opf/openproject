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

const eventTargetCache = new WeakMap<EventTarget, EventListenerRegistry>();

type EventType = keyof HTMLElementEventMap;
type EventNamespace = string;
type NamespacedEvent = `${EventType}.${EventNamespace}`;
type NamespacedEvents = `.${EventNamespace}`;
type EventListeners = EventListenerOrEventListenerObject[];

class EventListenerRegistry {
  private listenerMap = new Map<EventNamespace, Map<EventType, EventListeners>>();

  constructor(private eventTarget:EventTarget) {}

  on(
    namespacedEvent:NamespacedEvent,
    handler:EventListenerOrEventListenerObject,
    options?:AddEventListenerOptions|boolean
  ) {
    const [namespace, type] = this.getNamespaceAndType(namespacedEvent);

    this.listenerMap.set(namespace, this.listenerMap.get(namespace) ?? new Map<EventType, EventListeners>());
    const listenersForNamespace = this.listenerMap.get(namespace)!;

    if (!type) return;

    if (!listenersForNamespace.has(type)) {
      listenersForNamespace.set(type, [handler]);
    } else {
      const existingListeners = listenersForNamespace.get(type)!;
      if (!existingListeners.includes(handler)) {
        existingListeners.push(handler);
      }
    }

    this.eventTarget.addEventListener(type, handler, options);
  }

  one(
    namespacedEvent:NamespacedEvent,
    handler:EventListenerOrEventListenerObject,
    options?:AddEventListenerOptions
  ) {
    const wrappedHandler:EventListener = (event) => {
      this.removeHandlerFromRegistry(namespacedEvent, wrappedHandler);

      if (typeof handler === 'function') {
        handler(event);
      } else {
        handler.handleEvent(event);
      }
    };

    this.on(namespacedEvent, wrappedHandler, { ...options, once: true });
  }

  off(namespacedEvent:NamespacedEvent|NamespacedEvents) {
    const [namespace, type] = this.getNamespaceAndType(namespacedEvent);
    const listenersForNamespace = this.listenerMap.get(namespace);
    if (!listenersForNamespace) return;

    if (type) {
      const listeners = listenersForNamespace.get(type) ?? [];
      listeners.forEach((listener) => {
        this.eventTarget.removeEventListener(type, listener);
      });
      listenersForNamespace.delete(type);
    } else {
      listenersForNamespace.forEach((listeners, eventType) => {
        listeners.forEach((listener) => {
          this.eventTarget.removeEventListener(eventType, listener);
        });
      });
      this.listenerMap.delete(namespace);
    }

    // Clean up empty namespace
    if (listenersForNamespace.size === 0) {
      this.listenerMap.delete(namespace);
    }
  }

  private removeHandlerFromRegistry(namespacedEvent:NamespacedEvent, handler:EventListenerOrEventListenerObject) {
    const [namespace, type] = this.getNamespaceAndType(namespacedEvent);
    if (!namespace) return;

    const listenersForNamespace = this.listenerMap.get(namespace);
    if (!listenersForNamespace) return;

    if (!type) return;

    const listeners = listenersForNamespace.get(type);
    if (!listeners) return;

    const index = listeners.indexOf(handler);
    if (index > -1) {
      listeners.splice(index, 1);
    }

    if (listeners.length === 0) {
      listenersForNamespace.delete(type);
    }
    if (listenersForNamespace.size === 0) {
      this.listenerMap.delete(namespace);
    }
  }

  private getNamespaceAndType(namespacedEvent:NamespacedEvent|NamespacedEvents):[EventNamespace, EventType|null] {
    const parts = namespacedEvent.split('.').reverse();
    const namespace = parts[0];
    const type = (parts[1] as EventType | undefined) ?? null;
    return [namespace, type];
  }
}

export function target(eventTarget:EventTarget):EventListenerRegistry {
  if (!eventTargetCache.has(eventTarget)) {
    eventTargetCache.set(eventTarget, new EventListenerRegistry(eventTarget));
  }

  return eventTargetCache.get(eventTarget)!;
}
