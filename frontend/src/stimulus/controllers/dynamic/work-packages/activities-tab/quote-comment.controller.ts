/*
 * -- copyright
 * OpenProject is an open source project management software.
 * Copyright (C) 2023 the OpenProject GmbH
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

import { Controller } from '@hotwired/stimulus';

import type EditorController from './editor.controller';
import type InternalCommentController from './internal-comment.controller';

interface QuoteParams {
  userId:string;
  userName:string;
  textWrote:string;
  content:string;
  isInternal:boolean;
}

export default class QuoteCommentController extends Controller {
  static outlets = ['work-packages--activities-tab--editor', 'work-packages--activities-tab--internal-comment'];

  declare readonly workPackagesActivitiesTabEditorOutlet:EditorController;
  declare readonly workPackagesActivitiesTabInternalCommentOutlet:InternalCommentController;

  quote({ params: { userId, userName, textWrote, content, isInternal } }:{ params:QuoteParams }) {
    const quotedText = this.quotedText(content, userId, userName, textWrote);

    if (this.isFormVisible) {
      this.insertQuoteOnExistingEditor(quotedText);
    } else {
      this.openEditorWithInitialData(quotedText);
    }

    this.setCommentRestriction(isInternal);
  }

  private quotedText(rawComment:string, userId:string, userName:string, textWrote:string) {
    const quoted = rawComment.split('\n')
      .map((line:string) => `\n> ${line}`)
      .join('');

    // if we ever change CKEditor or how @mentions work this will break
    return `<mention class="mention" data-id="${userId}" data-type="user" data-text="@${userName}">@${userName}</mention> ${textWrote}:\n\n${quoted}`;
  }

  private insertQuoteOnExistingEditor(quotedText:string) {
    if (this.ckEditorInstance) {
      const editorData = this.ckEditorInstance.getData({ trim: false });

      if (editorData.endsWith('<br>') || editorData.endsWith('\n')) {
        this.ckEditorInstance.setData(`${editorData}${quotedText}`);
      } else {
        this.ckEditorInstance.setData(`${editorData}\n\n${quotedText}`);
      }
    }
  }

  private setCommentRestriction(isInternal:boolean) {
    if (isInternal && !this.workPackagesActivitiesTabInternalCommentOutlet.internalCheckboxTarget.checked) {
      this.workPackagesActivitiesTabInternalCommentOutlet.internalCheckboxTarget.checked = isInternal;
      this.workPackagesActivitiesTabInternalCommentOutlet.updateInternalState();
    }
  }

  private openEditorWithInitialData(quotedText:string) {
    this.workPackagesActivitiesTabEditorOutlet.openEditorWithInitialData(quotedText);
  }

  private get ckEditorInstance() {
    return this.workPackagesActivitiesTabEditorOutlet.ckEditorInstance;
  }

  private get isFormVisible():boolean {
    return !this.workPackagesActivitiesTabEditorOutlet.formRowTarget.classList.contains('d-none');
  }
}
