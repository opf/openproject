import { Controller } from '@hotwired/stimulus';

export default class CasesSelectionController extends Controller {
  static targets = [
    'mode',
    'checkboxColumn',
    'rowCheckbox',
    'selectAll',
    'actionBar',
    'count',
    'idsContainer',
  ];

  declare readonly modeTarget:HTMLInputElement;
  declare readonly hasModeTarget:boolean;
  declare readonly rowCheckboxTargets:HTMLInputElement[];
  declare readonly selectAllTarget:HTMLInputElement;
  declare readonly hasSelectAllTarget:boolean;
  declare readonly actionBarTarget:HTMLElement;
  declare readonly hasActionBarTarget:boolean;
  declare readonly countTarget:HTMLElement;
  declare readonly hasCountTarget:boolean;
  declare readonly idsContainerTargets:HTMLElement[];

  connect():void {
    this.refreshCount();
  }

  modeChanged():void {
    if (this.hasModeTarget && !this.modeTarget.checked) {
      this.clearSelection();
    }
    this.refreshCount();
  }

  toggleAll():void {
    if (!this.hasSelectAllTarget) {
      return;
    }

    const checked = this.selectAllTarget.checked;
    this.rowCheckboxTargets.forEach((box) => {
      box.checked = checked;
    });
    this.refreshCount();
  }

  selectionChanged():void {
    this.refreshCount();
    if (!this.hasSelectAllTarget) {
      return;
    }

    const total = this.rowCheckboxTargets.length;
    const selected = this.selectedIds().length;
    this.selectAllTarget.checked = total > 0 && selected === total;
    this.selectAllTarget.indeterminate = selected > 0 && selected < total;
  }

  beforeSubmit(event:Event):void {
    const ids = this.selectedIds();
    if (ids.length === 0) {
      event.preventDefault();
      return;
    }

    this.idsContainerTargets.forEach((container) => {
      container.replaceChildren();
      ids.forEach((id) => {
        const input = document.createElement('input');
        input.type = 'hidden';
        input.name = 'ids[]';
        input.value = id;
        container.appendChild(input);
      });
    });
  }

  private clearSelection():void {
    this.rowCheckboxTargets.forEach((box) => {
      box.checked = false;
    });
    if (this.hasSelectAllTarget) {
      this.selectAllTarget.checked = false;
      this.selectAllTarget.indeterminate = false;
    }
  }

  private selectedIds():string[] {
    return this.rowCheckboxTargets
      .filter((box) => box.checked)
      .map((box) => box.value);
  }

  private refreshCount():void {
    if (!this.hasCountTarget) {
      return;
    }

    const count = this.selectedIds().length;
    this.countTarget.textContent = String(count);

    if (!this.hasActionBarTarget) {
      return;
    }

    this.actionBarTarget.classList.toggle('is-disabled', count === 0);
    this.actionBarTarget.querySelectorAll<HTMLButtonElement>('button[type="submit"]').forEach((button) => {
      button.disabled = count === 0;
    });
  }
}
