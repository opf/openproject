/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
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

import { renderHook } from '@testing-library/react';
import { useAttachmentValidation } from './useAttachmentValidation';

function mockPluginContext(whitelist:string[]) {
  (window as unknown as { OpenProject:unknown }).OpenProject = {
    getPluginContext: () => Promise.resolve({
      services: {
        configurationService: { attachmentWhitelist: whitelist },
      },
    }),
  };
}

function mockFile(name:string, type:string):File {
  return new File([''], name, { type });
}

let originalOpenProject:unknown;
let originalI18n:unknown;

beforeEach(() => {
  const win = window as unknown as { OpenProject:unknown; I18n:unknown };
  originalOpenProject = win.OpenProject;
  originalI18n = win.I18n;
  win.I18n = { t: (_key:string, opts?:{ value?:string }) => `not allowed: ${opts?.value ?? ''}` };
});

afterEach(() => {
  const win = window as unknown as { OpenProject:unknown; I18n:unknown };
  win.OpenProject = originalOpenProject;
  win.I18n = originalI18n;
});

describe('useAttachmentValidation', () => {
  describe('when whitelist is empty', () => {
    it('allows any file', async () => {
      mockPluginContext([]);
      const { result } = renderHook(() => useAttachmentValidation());
      const validation = await result.current.validateFile(mockFile('photo.png', 'image/png'));
      expect(validation.valid).toBe(true);
    });
  });

  describe('when file.type is empty', () => {
    it('defers to the backend (allows the file)', async () => {
      mockPluginContext(['image/png']);
      const { result } = renderHook(() => useAttachmentValidation());
      const validation = await result.current.validateFile(mockFile('file.xyz', ''));
      expect(validation.valid).toBe(true);
    });
  });

  describe('bare MIME type entries', () => {
    it('allows a file whose MIME type is in the whitelist', async () => {
      mockPluginContext(['image/png', 'image/jpeg']);
      const { result } = renderHook(() => useAttachmentValidation());
      const validation = await result.current.validateFile(mockFile('photo.png', 'image/png'));
      expect(validation.valid).toBe(true);
    });

    it('rejects a file whose MIME type is not in the whitelist', async () => {
      mockPluginContext(['image/jpeg']);
      const { result } = renderHook(() => useAttachmentValidation());
      const validation = await result.current.validateFile(mockFile('photo.png', 'image/png'));
      expect(validation.valid).toBe(false);
    });
  });

  describe('extension glob entries (*.ext format)', () => {
    it('allows a file matching a *.ext glob', async () => {
      mockPluginContext(['*.png']);
      const { result } = renderHook(() => useAttachmentValidation());
      const validation = await result.current.validateFile(mockFile('photo.png', 'image/png'));
      expect(validation.valid).toBe(true);
    });

    it('does not match a *ext glob without a dot (backend also rejects this format)', async () => {
      mockPluginContext(['*png']);
      const { result } = renderHook(() => useAttachmentValidation());
      const validation = await result.current.validateFile(mockFile('photo.png', 'image/png'));
      expect(validation.valid).toBe(false);
    });

    it('is case-insensitive for the extension', async () => {
      mockPluginContext(['*.PNG']);
      const { result } = renderHook(() => useAttachmentValidation());
      const validation = await result.current.validateFile(mockFile('photo.png', 'image/png'));
      expect(validation.valid).toBe(true);
    });

    it('rejects a file whose extension is not in the whitelist', async () => {
      mockPluginContext(['*.jpg']);
      const { result } = renderHook(() => useAttachmentValidation());
      const validation = await result.current.validateFile(mockFile('photo.png', 'image/png'));
      expect(validation.valid).toBe(false);
    });
  });

  describe('rejected files', () => {
    it('returns a translated reason', async () => {
      mockPluginContext(['image/jpeg']);
      const { result } = renderHook(() => useAttachmentValidation());
      const validation = await result.current.validateFile(mockFile('photo.png', 'image/png'));
      expect(validation.valid).toBe(false);
      expect((validation as { valid:false; reason:string }).reason).toBe('not allowed: image/png');
    });
  });
});
