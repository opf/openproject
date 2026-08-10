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

import { Injectable } from '@angular/core';
import type CodeMirrorStatic from 'codemirror';

type CodeMirrorType = typeof CodeMirrorStatic;

@Injectable({ providedIn: 'root' })
export class CodeMirrorLoaderService {
  private codeMirrorPromise:Promise<CodeMirrorType>|undefined;

  private loadedModes = new Set<string>();
  private missingModes = new Set<string>();
  private modePromises = new Map<string, Promise<boolean>>();

  public async loadCore():Promise<CodeMirrorType> {
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore
    this.codeMirrorPromise ??= import('../../../../../../../node_modules/codemirror/lib/codemirror.js')
      .then((imported:{ default:CodeMirrorType }) => imported.default);

    return this.codeMirrorPromise;
  }

  public async ensureModeLoaded(language:string):Promise<boolean> {
    if (!language || language === 'text') {
      return true;
    }

    const normalizedLanguage = language.toLowerCase();

    if (this.loadedModes.has(normalizedLanguage)) {
      return true;
    }

    if (this.missingModes.has(normalizedLanguage)) {
      return false;
    }

    if (!this.modePromises.has(normalizedLanguage)) {
      this.modePromises.set(normalizedLanguage, this.loadMode(normalizedLanguage));
    }

    return this.modePromises.get(normalizedLanguage)!;
  }

  private async loadMode(language:string):Promise<boolean> {
    await this.loadCore();

    try {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore
      await import(`../../../../../../../node_modules/codemirror/mode/${language}/${language}.js`);

      this.loadedModes.add(language);
      return true;
    } catch {
      this.missingModes.add(language);
      return false;
    }
  }
}
