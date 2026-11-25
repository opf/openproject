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

interface NavigatorUAData {
  platform?:string;
  brands?:{ brand:string; version:string }[];
}

const FIRST_CHROMIUM_BADGING_MULTI_URL_DRAGS = 152;

function userAgentData():NavigatorUAData|undefined {
  return (navigator as Navigator & { userAgentData?:NavigatorUAData }).userAgentData;
}

/**
 * Whether the browser is running on an Apple platform.
 *
 * Matters for modifier keys: Ctrl-click is the secondary-click gesture on
 * macOS, where Cmd is the multi-select modifier instead. Treating Ctrl as
 * multi-select there fights the contextual menu.
 *
 * `navigator.platform` is deprecated but still the only universally
 * available signal, so `userAgentData` is preferred where a browser exposes
 * it.
 */
export function isApplePlatform():boolean {
  const platform = userAgentData()?.platform ?? navigator.platform;

  return /mac|iphone|ipad|ipod/i.test(platform);
}

/**
 * Whether the platform shows its own item count on a drag carrying several
 * `text/uri-list` URLs.
 *
 * From Chromium 152 on macOS, each URL becomes its own native dragging
 * item, and AppKit badges any drag with more than one item
 * (https://chromium-review.googlesource.com/c/chromium/src/+/7774364).
 * A count drawn into the drag preview would then show twice
 * (https://community.openproject.org/wp/AGILE-538).
 *
 * Chromium exposes `userAgentData` only in secure contexts, so plain-HTTP
 * installations fall back to the user-agent string.
 */
export function platformBadgesMultiUrlDrags():boolean {
  const uaData = userAgentData();
  if (uaData === undefined) {
    return userAgentBadgesMultiUrlDrags();
  }

  const chromium = uaData.brands?.find(({ brand }) => brand === 'Chromium');

  return uaData.platform === 'macOS'
    && chromium !== undefined
    && parseInt(chromium.version, 10) >= FIRST_CHROMIUM_BADGING_MULTI_URL_DRAGS;
}

function userAgentBadgesMultiUrlDrags():boolean {
  const { userAgent } = navigator;
  const chromeVersion = /\bChrome\/(\d+)/.exec(userAgent)?.[1];

  return userAgent.includes('Macintosh')
    && chromeVersion !== undefined
    && parseInt(chromeVersion, 10) >= FIRST_CHROMIUM_BADGING_MULTI_URL_DRAGS;
}
