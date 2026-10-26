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

import { vi } from 'vitest';

import { decodeImageFile, updateObjectUrlPreview } from './object-url-preview';

// A minimal, valid 1x1 transparent PNG, so Image#decode() has real pixel data to decode.
const ONE_PIXEL_PNG_BASE64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';

function pngFile(name = 'pixel.png'):File {
  const bytes = Uint8Array.from(atob(ONE_PIXEL_PNG_BASE64), (character) => character.charCodeAt(0));
  return new File([bytes], name, { type: 'image/png' });
}

describe('object-url-preview', () => {
  describe('updateObjectUrlPreview', () => {
    it('creates an object URL for a new source', () => {
      const url = updateObjectUrlPreview(undefined, pngFile());

      expect(url).toMatch(/^blob:/);
    });

    it('revokes the previous URL when swapping in a new source', () => {
      const revokeSpy = vi.spyOn(URL, 'revokeObjectURL');
      const first = updateObjectUrlPreview(undefined, pngFile('first.png'));

      const second = updateObjectUrlPreview(first, pngFile('second.png'));

      expect(revokeSpy).toHaveBeenCalledWith(first);
      expect(second).not.toEqual(first);
    });

    it('revokes the previous URL and returns undefined when no new source is given', () => {
      const revokeSpy = vi.spyOn(URL, 'revokeObjectURL');
      const url = updateObjectUrlPreview(undefined, pngFile());

      const result = updateObjectUrlPreview(url, undefined);

      expect(revokeSpy).toHaveBeenCalledWith(url);
      expect(result).toBeUndefined();
    });

    it('returns undefined without revoking anything when there is nothing to show or clear', () => {
      const revokeSpy = vi.spyOn(URL, 'revokeObjectURL');

      expect(updateObjectUrlPreview(undefined, undefined)).toBeUndefined();
      expect(revokeSpy).not.toHaveBeenCalled();
    });
  });

  describe('decodeImageFile', () => {
    it('decodes a file into a loaded image element', async () => {
      const image = await decodeImageFile(pngFile());

      expect(image).toBeInstanceOf(HTMLImageElement);
      expect(image.naturalWidth).toBe(1);
      expect(image.naturalHeight).toBe(1);
    });

    it('revokes the object URL used to decode the image', async () => {
      const revokeSpy = vi.spyOn(URL, 'revokeObjectURL');

      await decodeImageFile(pngFile());

      expect(revokeSpy).toHaveBeenCalledOnce();
    });
  });
});
