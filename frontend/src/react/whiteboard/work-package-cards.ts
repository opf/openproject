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

import { newElementWith, restoreElements } from '@excalidraw/excalidraw';
import type { ExcalidrawElement, ExcalidrawEmbeddableElement } from '@excalidraw/excalidraw/element/types';
import { WP_ID_URL_PATTERN } from 'core-app/shared/helpers/work-package-id-pattern';

export const WORK_PACKAGE_CARD_SIZE = { width: 320, height: 112 };

const REFERENCE_REGEX = new RegExp(`^#(${WP_ID_URL_PATTERN})$`);
const PATH_REGEX = new RegExp(`/(?:wp|work_packages)(?:/details)?/(${WP_ID_URL_PATTERN})(?:/|$)`);

export interface WorkPackageCardContext {
  origin:string;
  basePath:string;
}

export function currentCardContext():WorkPackageCardContext {
  return { origin: window.location.origin, basePath: window.appBasePath || '' };
}

function idFromUrl(text:string, context:WorkPackageCardContext):string|null {
  let url:URL;
  try {
    url = new URL(text);
  } catch {
    return null;
  }

  if (url.origin !== context.origin || !url.pathname.startsWith(`${context.basePath}/`)) return null;

  return PATH_REGEX.exec(url.pathname.slice(context.basePath.length))?.[1] ?? null;
}

/**
 * Recognizes `#123`, `#PROJ-42` and links to a work package of this instance.
 */
export function workPackageIdFromText(text:string, context = currentCardContext()):string|null {
  const candidate = text.trim();
  if (/\s/.test(candidate)) return null;

  return REFERENCE_REGEX.exec(candidate)?.[1] ?? idFromUrl(candidate, context);
}

export function workPackageCardLink(id:string, context = currentCardContext()):string {
  return `${context.origin}${context.basePath}/wp/${encodeURIComponent(id)}`;
}

export function workPackageIdFromCardLink(link:string|null, context = currentCardContext()):string|null {
  if (!link) return null;

  const prefix = `${context.origin}${context.basePath}/wp/`;
  if (!link.startsWith(prefix)) return null;

  const id = decodeURIComponent(link.slice(prefix.length));
  return new RegExp(`^(?:${WP_ID_URL_PATTERN})$`).test(id) ? id : null;
}

export function newWorkPackageCardElement(id:string, center:{ x:number; y:number }, context = currentCardContext()):ExcalidrawEmbeddableElement {
  const skeleton:Partial<ExcalidrawEmbeddableElement> = {
    type: 'embeddable',
    link: workPackageCardLink(id, context),
    x: center.x - (WORK_PACKAGE_CARD_SIZE.width / 2),
    y: center.y - (WORK_PACKAGE_CARD_SIZE.height / 2),
    ...WORK_PACKAGE_CARD_SIZE,
    customData: { hideLink: true },
    strokeColor: 'transparent',
    backgroundColor: 'transparent',
    seed: Math.floor(Math.random() * 2 ** 31),
    versionNonce: Math.floor(Math.random() * 2 ** 31),
  };

  const [element] = restoreElements([skeleton as ExcalidrawElement], null);
  return element as ExcalidrawEmbeddableElement;
}

export function isWorkPackageCard(element:ExcalidrawElement, context = currentCardContext()):element is ExcalidrawEmbeddableElement {
  return element.type === 'embeddable' && workPackageIdFromCardLink(element.link, context) !== null;
}

// Cards placed before the hideLink flag existed still show Excalidraw's link icon and popup.
export function cardsWithoutHiddenLink(elements:readonly ExcalidrawElement[], context = currentCardContext()):ExcalidrawElement[]|null {
  const migrated = elements.filter((element) => !element.isDeleted && isWorkPackageCard(element, context) && !element.customData?.hideLink);
  if (migrated.length === 0) return null;

  return migrated.map((element) => newElementWith(element, { customData: { ...element.customData, hideLink: true } }));
}
