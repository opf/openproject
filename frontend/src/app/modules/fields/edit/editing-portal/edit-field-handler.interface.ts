// -- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
// ++

export interface IEditFieldHandler {
  /**
   * Whether the handler belongs to a larger edit mode form
   * e.g., WP-create
   */
  inEditMode:boolean;

  /** Whether the field is currently active */
  active:boolean;

  /**
   * Return a unique ID for this edit field
   */
  htmlId:string;

  /**
   * Accessibility label for the field
   */
  fieldLabel:string;

  /**
   * Error messages on the field, if any.
   */
  errorMessageOnLabel?:string;

  /**
   * Stop event propagation
   */
  stopPropagation(evt:JQueryEventObject):boolean;

  /**
   * Focus on the active field.
   * Optionally, try to set the click position to the given offset if the field is an input element.
   */
  focus(setClickOffset?:number):void;

  /**
   * Handle a user submitting the field (e.g, ng-change)
   */
  handleUserSubmit():Promise<any>;

  /**
   * Handle users pressing enter inside an edit mode.
   * Outside an edit mode, the regular save event is captured by handleUserSubmit (submit event).
   * In an edit mode, we can't derive from a submit event wheteher the user pressed enter
   * (and on what field he did that).
   */
  handleUserKeydown(event:JQueryEventObject, onlyCancel?:boolean):void;

  /**
   * Cancel edit
   */
  handleUserCancel():void;

  /**
   * Cancel any pending changes
   */
  reset():void;

  /**
   * Close the field, resetting it with its display value.
   */
  deactivate(focus:boolean):void;

  /**
   * Returns whether the field has been changed
   */
  isChanged():boolean;
}
