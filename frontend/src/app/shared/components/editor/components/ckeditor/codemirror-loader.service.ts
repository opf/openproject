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
