import { Controller } from '@hotwired/stimulus';
import * as CodeMirror from 'codemirror';
import 'codemirror/mode/yaml/yaml';

export default class CodemirrorController extends Controller {
  static targets = ['source'];

  declare readonly sourceTarget:HTMLTextAreaElement;

  static values = {
    mode: String,
  };

  declare modeValue:string;

  connect() {
    this.initCodeMirror();
  }

  initCodeMirror() {
    CodeMirror.fromTextArea(
      this.sourceTarget,
      {
        lineNumbers: true,
        smartIndent: true,
        autofocus: true,
        mode: this.modeValue,
      },
    ).setSize('100%', Math.max(300, window.innerHeight / 2));
  }
}
