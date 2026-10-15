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

export function decodeBase64Url(value:string):Uint8Array<ArrayBuffer> {
  // The key is base64url without padding; atob only accepts standard base64.
  const base64 = value.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(value.length / 4) * 4, '=');
  return Uint8Array.from(atob(base64), (char) => char.charCodeAt(0));
}

export function boundToKey(subscription:PushSubscription, key:string):boolean {
  const bound = subscription.options.applicationServerKey;
  if (!bound) return true;

  const current = decodeBase64Url(key);
  const boundBytes = new Uint8Array(bound);
  return boundBytes.length === current.length && boundBytes.every((byte, index) => byte === current[index]);
}

export async function currentPushSubscription():Promise<PushSubscription|null|undefined> {
  const registration = await navigator.serviceWorker.getRegistration();
  return registration?.pushManager.getSubscription();
}
