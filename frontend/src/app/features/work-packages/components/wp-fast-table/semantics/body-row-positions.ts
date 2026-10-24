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

export interface BodyRowPositions {
  readonly count:number;
  readonly ordinals:ReadonlyMap<string, number>;
}

export interface PositionGroup {
  readonly headerKey:string;
  readonly sumsKey:string;
  readonly count:number;
  readonly hasSums:boolean;
}

export interface PositionWindow {
  readonly pageNumber:number;
  readonly pageSize:number;
  readonly total:number;
  readonly primaryKeys:readonly string[];
  readonly groups:readonly PositionGroup[];
}

export function bodyRowPositions(window:PositionWindow):BodyRowPositions|null {
  const { pageNumber, pageSize, total, primaryKeys, groups } = window;
  if (!Number.isSafeInteger(pageNumber) || pageNumber < 1
    || !Number.isSafeInteger(pageSize) || pageSize < 1
    || !Number.isSafeInteger(total) || total < 0
    || primaryKeys.length > pageSize) {
    return null;
  }

  const firstQueryRank = (pageNumber - 1) * pageSize;
  const lastQueryRank = firstQueryRank + primaryKeys.length;
  if (!Number.isSafeInteger(firstQueryRank) || !Number.isSafeInteger(lastQueryRank)
    || (primaryKeys.length > 0 && lastQueryRank > total)) {
    return null;
  }

  const ordinals = new Map<string, number>();
  const add = (key:string, ordinal:number):boolean => {
    if (ordinals.has(key) || !Number.isSafeInteger(ordinal) || ordinal < 1) {
      return false;
    }
    ordinals.set(key, ordinal);
    return true;
  };

  if (groups.length === 0) {
    for (const [index, key] of primaryKeys.entries()) {
      if (!add(key, firstQueryRank + index + 1)) {
        return null;
      }
    }
    return { count: total, ordinals };
  }

  let queryPrefix = 0;
  let bodyPrefix = 0;
  const boundaries:{ queryPrefix:number; queryEnd:number; headerOrdinal:number }[] = [];
  for (const group of groups) {
    if (!Number.isSafeInteger(group.count) || group.count < 0) {
      return null;
    }
    if (group.count === 0) {
      continue;
    }

    const headerOrdinal = bodyPrefix + 1;
    const queryEnd = queryPrefix + group.count;
    const bodyEnd = bodyPrefix + group.count + 1 + Number(group.hasSums);
    if (!Number.isSafeInteger(queryEnd) || !Number.isSafeInteger(bodyEnd)
      || !add(group.headerKey, headerOrdinal)
      || (group.hasSums && !add(group.sumsKey, bodyEnd))) {
      return null;
    }
    boundaries.push({ queryPrefix, queryEnd, headerOrdinal });
    queryPrefix = queryEnd;
    bodyPrefix = bodyEnd;
  }

  if (queryPrefix !== total) {
    return null;
  }

  let groupIndex = 0;
  for (const [index, key] of primaryKeys.entries()) {
    const rank = firstQueryRank + index;
    while (groupIndex < boundaries.length && rank >= boundaries[groupIndex].queryEnd) {
      groupIndex += 1;
    }
    const boundary = boundaries[groupIndex];
    if (!boundary || !add(key, boundary.headerOrdinal + 1 + (rank - boundary.queryPrefix))) {
      return null;
    }
  }

  return { count: bodyPrefix, ordinals };
}

export interface DraftRow {
  readonly key:string;
  readonly member:boolean;
}

interface MemberRange {
  readonly first:number;
  readonly last:number;
  readonly sumsKey:string;
}

export function draftAgrees(body:BodyRowPositions, rows:readonly DraftRow[], groups:readonly PositionGroup[]):boolean {
  const ranges = new Map<string, MemberRange>();
  for (const group of groups) {
    if (group.count === 0) {
      continue;
    }
    const header = body.ordinals.get(group.headerKey);
    if (header === undefined) {
      return false;
    }
    ranges.set(group.headerKey, { first: header + 1, last: header + group.count, sumsKey: group.sumsKey });
  }

  let active:MemberRange|undefined;
  let previous = 0;
  for (const row of rows) {
    const ordinal = body.ordinals.get(row.key);
    if (ordinal === undefined || ordinal <= previous) {
      return false;
    }
    const range = ranges.get(row.key);
    if (range) {
      active = range;
    } else if (groups.length > 0) {
      if (!active) {
        return false;
      }
      if (row.member ? ordinal < active.first || ordinal > active.last : row.key !== active.sumsKey) {
        return false;
      }
    }
    previous = ordinal;
  }
  return true;
}
