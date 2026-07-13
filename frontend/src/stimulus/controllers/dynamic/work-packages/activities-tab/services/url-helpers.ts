/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

export enum ActivityAnchorType {
  Comment = 'comment',
  Activity = 'activity',
}

export interface ActivityAnchor {
  type:ActivityAnchorType;
  id:string;
}

const anchorTypeRegex = new RegExp(`#(${ActivityAnchorType.Comment}|${ActivityAnchorType.Activity})-(\\d+)`, 'i');

export namespace UrlHelpers {
  /**
   * Extracts activity anchor information from a URL anchor string.
   *
   * @param anchor - The anchor string to parse (e.g., "#comment-80", "#activity-45")
   * @returns An ActivityAnchor object containing the type and id, or null if parsing fails
   *
   * @example
   * ```typescript
   * const result = extractActivityAnchor("#comment-80");
   * // Returns: { type: "comment", id: "80" }
   * ```
   */
  export function extractActivityAnchor(anchor:string):ActivityAnchor | null {
    const activityIdMatch = anchor.match(anchorTypeRegex); // Ex. [ "#comment-80", "comment", "80" ]

    if (activityIdMatch?.[1] && activityIdMatch?.[2]) {
      const type = activityIdMatch[1];
      if (Object.values(ActivityAnchorType).includes(type as ActivityAnchorType)) {
        return { type: type as ActivityAnchorType, id: activityIdMatch[2] };
      }
    }
    return null;
  }

  /**
   * Translates a legacy `activity` anchor into its canonical `comment` anchor
   * using the comment id the server resolved it to. Comment anchors, and activity
   * anchors the server could not resolve, are returned unchanged.
   *
   * @example
   * ```typescript
   * canonicalActivityAnchor({ type: "activity", id: "5" }, 456);
   * // Returns: { type: "comment", id: "456" }
   * ```
   */
  export function canonicalActivityAnchor(anchor:ActivityAnchor, resolvedCommentId:number | null):ActivityAnchor {
    if (anchor.type !== ActivityAnchorType.Activity || !resolvedCommentId) {
      return anchor;
    }

    return { type: ActivityAnchorType.Comment, id: String(resolvedCommentId) };
  }
}
