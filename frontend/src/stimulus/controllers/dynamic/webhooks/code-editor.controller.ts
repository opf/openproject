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

export default class CodeEditorController extends Controller<HTMLElement> {
  static targets = ['textarea', 'command'];

  declare readonly textareaTarget:HTMLTextAreaElement;
  declare readonly commandTarget:HTMLInputElement;
  declare readonly hasCommandTarget:boolean;

  private loader = new CodeMirrorLoaderService();
  private editor:EditorFromTextArea|undefined;

  private modeRequest = 0;

  connect() {
    void this.setupEditor();
  }

  private async setupEditor() {
    const CodeMirror = await this.loader.loadCore();

    this.editor = CodeMirror.fromTextArea(this.textareaTarget, {
      lineNumbers: true,
      indentUnit: 4,
      tabSize: 4,
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
    this.editor.setSize(null, '32rem');
    const editor = this.editor;
    editor.on('change', () => editor.save());

    await this.updateMode();
  }

  disconnect() {
    this.editor?.toTextArea();
    this.editor = undefined;
  }

  async updateMode() {
    const program = this.hasCommandTarget ? this.commandTarget.value.trim().split(/\s+/)[0] : '';
    const command = program.split('/').pop() ?? '';
    const mode = MODES[command.toLowerCase()] ?? '';
    const request = ++this.modeRequest;
    const loaded = await this.loader.ensureModeLoaded(mode);
    if (request === this.modeRequest) {
      this.editor?.setOption('mode', loaded ? mode : '');
    }
  }
}
