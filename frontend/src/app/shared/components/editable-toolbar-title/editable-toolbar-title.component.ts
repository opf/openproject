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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++
import {
  Component,
  ElementRef,
  EventEmitter,
  HostBinding,
  Injector,
  Input,
  OnChanges,
  OnInit,
  Output,
  SimpleChanges,
  ViewChild,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { whenOutside } from 'core-app/shared/directives/focus/contain-helpers';
import { InjectField } from 'core-app/shared/helpers/angular/inject-field.decorator';

export const triggerEditingEvent = 'op:selectableTitle:trigger';
export const selectableTitleIdentifier = 'editable-toolbar-title';

@Component({
  selector: 'editable-toolbar-title',
  templateUrl: './editable-toolbar-title.html',
  styleUrls: ['./editable-toolbar-title.sass'],
})
export class EditableToolbarTitleComponent implements OnInit, OnChanges {
  @Input('title') public inputTitle:string;

  @Input() public editable = true;

  @Input() public inFlight = false;

  @Input() public showSaveCondition = false;

  @Input() public initialFocus = false;

  @Input() public smallHeader = false;

  @Output() public onSave = new EventEmitter<string>();

  @Output() public onEmptySubmit = new EventEmitter<void>();

  @HostBinding('class.title-container') baseClass = true;

  @HostBinding('class.title-container_editable')
  public get editableClass():boolean {
    return this.editable;
  }

  @ViewChild('editableTitleInput') inputField?:ElementRef;

  public selectedTitle:string;

  public selectableTitleIdentifier = selectableTitleIdentifier;

  @InjectField() protected readonly elementRef:ElementRef;

  @InjectField() I18n!:I18nService;

  public text = {
    click_to_edit: this.I18n.t('js.work_packages.query.click_to_edit_query_name'),
    press_enter_to_save: this.I18n.t('js.label_press_enter_to_save'),
    query_has_changed_click_to_save: this.I18n.t('js.label_view_has_changed'),
    input_title: '',
    input_placeholder: this.I18n.t('js.work_packages.query.rename_query_placeholder'),
    confirm_edit_cancel: this.I18n.t('js.work_packages.query.confirm_edit_cancel'),
    duplicate_query_title: this.I18n.t('js.work_packages.query.errors.duplicate_query_title'),
  };

  constructor(readonly injector:Injector) {
  }

  ngOnInit():void {
    this.text.input_title = `${this.text.click_to_edit} ${this.text.press_enter_to_save}`;

    jQuery(this.elementRef.nativeElement).on(triggerEditingEvent, (evt:Event, val = '') => {
      // In case we're not editable, ignore request
      if (!this.inputField) {
        return;
      }

      this.selectedTitle = val;
      setTimeout(() => {
        const field:HTMLInputElement = this.inputField!.nativeElement;
        field.focus();
      }, 20);

      evt.stopPropagation();
    });
  }

  ngOnChanges(changes:SimpleChanges):void {
    if (changes.inputTitle) {
      this.selectedTitle = changes.inputTitle.currentValue;
    }

    if (changes.initialFocus && changes.initialFocus.firstChange && this.inputField!) {
      const field:HTMLInputElement = this.inputField.nativeElement;
      this.selectInputOnInitalFocus(field);
    }
  }

  public onFocus(event:FocusEvent):void {
    this.toggleToolbarButtonVisibility(true);
    this.selectInputOnInitalFocus(event.target as HTMLInputElement);
  }

  public onBlur():void {
    this.toggleToolbarButtonVisibility(false);
  }

  public selectInputOnInitalFocus(input:HTMLInputElement):void {
    if (this.initialFocus) {
      input.select();
      this.initialFocus = false;
    }
  }

  public saveWhenFocusOutside($event:FocusEvent):void {
    whenOutside(this.elementRef.nativeElement, () => this.save($event));
  }

  public reset():void {
    this.resetInputField();
    this.selectedTitle = this.inputTitle;
  }

  public get showSave():boolean {
    return this.editable && this.showSaveCondition;
  }

  public save($event:Event, force = false):void {
    $event.preventDefault();

    this.resetInputField();
    this.selectedTitle = this.selectedTitle.trim();

    // If the title is empty, show an error
    if (this.isEmpty) {
      this.onEmptyError();
      return;
    }

    if (!force && this.inputTitle === this.selectedTitle) {
      return; // Nothing changed
    }

    // Blur this element
    if (this.inputField) {
      (this.inputField.nativeElement as HTMLInputElement).blur();
    }

    // Avoid double saving
    if (this.inFlight) {
      return;
    }

    this.inFlight = true;

    this.emitSave(this.selectedTitle);

    // Unset in-flight after some delay not to trigger the blur
    setTimeout(() => this.inFlight = false, 100);
  }

  public get isEmpty():boolean {
    return this.selectedTitle === '';
  }

  /**
   * Called when saving the changed title
   */
  private emitSave(title:string):void {
    this.onSave.emit(title);
  }

  /**
   * Called when trying to save an empty text
   */
  private onEmptyError():void {
    // this.updateItemInMenu();  // Throws an error message, when name is empty
    this.onEmptySubmit.emit();
    this.focusInputOnError();
  }

  private focusInputOnError():void {
    if (this.inputField) {
      const el = this.inputField.nativeElement;
      el.classList.add('-error');
      el.focus();
    }
  }

  private resetInputField():void {
    if (this.inputField) {
      const el = this.inputField.nativeElement;
      el.classList.remove('-error');
    }
  }

  private toggleToolbarButtonVisibility(hidden:boolean):void {
    jQuery('.toolbar-items').toggleClass('hidden-for-mobile', hidden);
  }
}
