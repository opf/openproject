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

import { useEffect } from 'react';

const CLICK_TOLERANCE_PX = 5;

function contains(rect:DOMRect, x:number, y:number):boolean {
  return x >= rect.left && x <= rect.right && y >= rect.top && y <= rect.bottom;
}

export function cardSubjectAt(root:ParentNode, x:number, y:number):HTMLAnchorElement|null {
  const subjects = root.querySelectorAll<HTMLAnchorElement>('[data-whiteboard-card-subject]');
  return Array.from(subjects).find((subject) => contains(subject.getBoundingClientRect(), x, y)) ?? null;
}

// Card content never receives pointer events, which is what lets Excalidraw drag cards. A press and
// release on a card subject without moving in between therefore opens the work package from here.
export function useCardSubjectClicks(root:HTMLElement|null) {
  useEffect(() => {
    if (!root) return undefined;

    let press:{ x:number; y:number; pointerId:number }|null = null;
    const onPointerDown = (event:PointerEvent) => {
      press = event.isPrimary ? { x: event.clientX, y: event.clientY, pointerId: event.pointerId } : null;
    };
    const onPointerUp = (event:PointerEvent) => {
      const start = press;
      press = null;
      if (start?.pointerId !== event.pointerId) return;
      if (Math.hypot(event.clientX - start.x, event.clientY - start.y) > CLICK_TOLERANCE_PX) return;

      const subject = cardSubjectAt(root, event.clientX, event.clientY);
      if (subject) window.open(subject.href, '_blank', 'noopener');
    };

    root.addEventListener('pointerdown', onPointerDown, true);
    root.addEventListener('pointerup', onPointerUp, true);
    return () => {
      root.removeEventListener('pointerdown', onPointerDown, true);
      root.removeEventListener('pointerup', onPointerUp, true);
    };
  }, [root]);
}
