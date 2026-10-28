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

/**
 * Swaps an object URL preview for a new source, revoking the previous one so it does not leak.
 * Pass `undefined` as `source` to just revoke the previous URL (e.g. on controller disconnect).
 *
 * @param previousUrl The object URL returned by an earlier call, if any
 * @param source The new file/blob to preview, or undefined to clear the preview
 */
export function updateObjectUrlPreview(previousUrl:string | undefined, source:File | Blob | undefined):string | undefined {
  if (previousUrl) URL.revokeObjectURL(previousUrl);

  return source ? URL.createObjectURL(source) : undefined;
}

/**
 * Decodes a file into an `HTMLImageElement`, e.g. so it can be drawn onto a canvas for resizing.
 * The object URL used to load it is only needed for decoding, so it is revoked again immediately
 * afterwards — the decoded image keeps its pixel data regardless.
 */
export async function decodeImageFile(file:File):Promise<HTMLImageElement> {
  const url = URL.createObjectURL(file);
  try {
    const image = new Image();
    image.src = url;
    await image.decode();
    return image;
  } finally {
    URL.revokeObjectURL(url);
  }
}
