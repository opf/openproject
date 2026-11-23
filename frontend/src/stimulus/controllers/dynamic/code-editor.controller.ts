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

import { Controller } from '@hotwired/stimulus';
import type { EditorFromTextArea } from 'codemirror';
import { CodeMirrorLoaderService } from 'core-app/shared/components/editor/components/ckeditor/codemirror-loader.service';

const MODES:Record<string, string> = {
  python: 'python',
  python3: 'python',
  bash: 'shell',
  sh: 'shell',
  ruby: 'ruby',
  node: 'javascript',
};

// Delay after the last keystroke before announcing the change, so listeners don't react to every key.
const CHANGE_EVENT_DELAY = 300;

export default class CodeEditorController extends Controller<HTMLElement> {
  static targets = ['textarea', 'command'];

  static values = { mode: String, height: { type: String, default: '32rem' } };

  declare readonly modeValue:string;
  declare readonly hasModeValue:boolean;
  declare readonly heightValue:string;

  declare readonly textareaTarget:HTMLTextAreaElement;
  declare readonly commandTarget:HTMLInputElement;
  declare readonly hasCommandTarget:boolean;

  private loader = new CodeMirrorLoaderService();
  private editor:EditorFromTextArea|undefined;

  private modeRequest = 0;

  private changeTimer:ReturnType<typeof setTimeout>|undefined;

  connect() {
    void this.setupEditor();
  }

  private async setupEditor() {
    const CodeMirror = await this.loader.loadCore();

    const indent = this.modeValue === 'json' ? 2 : 4;
    this.editor = CodeMirror.fromTextArea(this.textareaTarget, {
      lineNumbers: true,
      indentUnit: indent,
      tabSize: indent,
      indentWithTabs: false,
      smartIndent: true,
      lineWrapping: false,
      extraKeys: {
        Tab: (cm) => {
          if (cm.somethingSelected()) {
            cm.indentSelection('add');
          } else {
            cm.replaceSelection(' '.repeat(cm.getOption('indentUnit') ?? 4));
          }
        },
        'Shift-Tab': (cm) => cm.indentSelection('subtract'),
      },
    });
    this.editor.getWrapperElement().style.lineHeight = '1.45';
    this.editor.setSize(null, this.heightValue);
    const editor = this.editor;
    editor.on('change', () => {
      editor.save();
      clearTimeout(this.changeTimer);
      this.changeTimer = setTimeout(() => this.dispatch('changed'), CHANGE_EVENT_DELAY);
    });

    await this.updateMode();
  }

  disconnect() {
    clearTimeout(this.changeTimer);
    this.editor?.toTextArea();
    this.editor = undefined;
  }

  async updateMode() {
    if (this.hasModeValue) {
      const json = this.modeValue === 'json';
      await this.applyMode(json ? 'javascript' : this.modeValue, json ? 'application/json' : this.modeValue);
      return;
    }

    const program = this.hasCommandTarget ? this.commandTarget.value.trim().split(/\s+/)[0] : '';
    const command = program.split('/').pop() ?? '';
    const mode = MODES[command.toLowerCase()] ?? '';
    await this.applyMode(mode, mode);
  }

  private async applyMode(module:string, mode:string) {
    const request = ++this.modeRequest;
    const loaded = await this.loader.ensureModeLoaded(module);
    if (request === this.modeRequest) {
      this.editor?.setOption('mode', loaded ? mode : '');
    }
  }
}
