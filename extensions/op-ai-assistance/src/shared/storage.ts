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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import browser from 'webextension-polyfill';
import { DEFAULT_SETTINGS } from './defaults';
import type { Chat, RunEvent, Settings } from './types';

const SETTINGS_KEY = 'settings';
const CHATS_PREFIX = 'chats:';
const MAX_CHATS = 20;

export async function loadSettings():Promise<Settings> {
  const stored = (await browser.storage.local.get(SETTINGS_KEY))[SETTINGS_KEY] as Partial<Settings> | undefined;
  return { ...DEFAULT_SETTINGS, ...stored };
}

export async function saveSettings(settings:Settings):Promise<void> {
  await browser.storage.local.set({ [SETTINGS_KEY]: settings });
}

const chatsKey = (origin:string, workPackageId:string):string => `${CHATS_PREFIX}${origin}:${workPackageId}`;

export async function loadChats(origin:string, workPackageId:string):Promise<Chat[]> {
  const key = chatsKey(origin, workPackageId);
  return ((await browser.storage.local.get(key))[key] as Chat[] | undefined) ?? [];
}

const MAX_STORED_TEXT = 2_000;

// The stored copy of an event drops the full prompt and the tool results, which hold the
// whole context and can be large: browser storage is limited.
export function storableEvent(event:RunEvent):RunEvent {
  switch (event.type) {
    case 'request':
      return { ...event, system: `(${event.system.length} characters, not stored)` };
    case 'tool_call':
      return { ...event, result: undefined };
    case 'answer':
      return { ...event, content: event.content.slice(0, MAX_STORED_TEXT) };
    case 'thought':
      return { ...event, text: event.text.slice(0, MAX_STORED_TEXT) };
    default:
      return event;
  }
}

function storableChat(chat:Chat):Chat {
  return { ...chat, messages: chat.messages.map((message) => ({ ...message, events: message.events.map(storableEvent) })) };
}

// Saves read, change and write one list, so they run one after the other: two saves close
// together (apply, then dismiss) would otherwise overwrite each other.
let saving:Promise<unknown> = Promise.resolve();

export function saveChat(origin:string, chat:Chat):Promise<void> {
  const save = saving.catch(() => undefined).then(async () => {
    const chats = (await loadChats(origin, chat.workPackageId)).filter((existing) => existing.id !== chat.id);
    await browser.storage.local.set({ [chatsKey(origin, chat.workPackageId)]: [storableChat(chat), ...chats].slice(0, MAX_CHATS) });
  });
  saving = save;
  return save;
}

export async function deleteAllChats():Promise<number> {
  const keys = Object.keys(await browser.storage.local.get(null)).filter((key) => key.startsWith(CHATS_PREFIX));
  await browser.storage.local.remove(keys);
  return keys.length;
}

export function newId():string {
  return crypto.randomUUID();
}
