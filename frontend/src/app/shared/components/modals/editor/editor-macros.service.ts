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

import { OpModalService } from 'core-app/shared/components/modal/modal.service';
import { Injectable, Injector } from '@angular/core';
import {
  WpButtonMacroModalComponent,
} from 'core-app/shared/components/modals/editor/macro-wp-button-modal/wp-button-macro.modal';
import {
  WikiIncludePageMacroModalComponent,
} from 'core-app/shared/components/modals/editor/macro-wiki-include-page-modal/wiki-include-page-macro.modal';
import {
  CodeBlockMacroModalComponent,
} from 'core-app/shared/components/modals/editor/macro-code-block-modal/code-block-macro.modal';
import {
  ChildPagesMacroModalComponent,
} from 'core-app/shared/components/modals/editor/macro-child-pages-modal/child-pages-macro.modal';
import { PortalOutletTarget } from 'core-app/shared/components/modal/portal-outlet-target.enum';

@Injectable()
export class EditorMacrosService {
  constructor(
    readonly opModalService:OpModalService,
    readonly injector:Injector,
  ) {
  }

  /**
   * Show a modal to edit the work package button macro settings.
   * Used from within ckeditor-augmented-textarea.
   */
  public configureWorkPackageButton(typeName?:string, classes?:string):Promise<{ type:string, classes:string }> {
    return new Promise<{ type:string, classes:string }>((resolve, _) => {
      this.opModalService.show(
        WpButtonMacroModalComponent,
        this.injector,
        { type: typeName, classes },
      ).subscribe((modal) => modal.closingEvent.subscribe(() => {
        if (modal.changed) {
          resolve({ type: modal.type, classes: modal.classes });
        }
      }));
    });
  }

  /**
   * Show a modal to edit the wiki include macro.
   * Used from within ckeditor-augmented-textarea.
   */
  public configureWikiPageInclude(page:string):Promise<string> {
    return new Promise<string>((resolve, _) => {
      const pageValue = page || '';
      this.opModalService.show(
        WikiIncludePageMacroModalComponent,
        this.injector,
        { page: pageValue },
      ).subscribe((modal) => modal.closingEvent.subscribe(() => {
        if (modal.changed) {
          resolve(modal.page);
        }
      }));
    });
  }

  /**
   * Show a modal to show an enhanced code editor for editing code blocks.
   * Used from within ckeditor-augmented-textarea.
   */
  public editCodeBlock(content:string, languageClass:string):Promise<{ content:string, languageClass:string }> {
    return new Promise<{ content:string, languageClass:string }>((resolve, _) => {
      const target = document.querySelector('opce-custom-modal-overlay') ? PortalOutletTarget.Custom : PortalOutletTarget.Default;

      this.opModalService.show(
        CodeBlockMacroModalComponent,
        this.injector,
        { content, languageClass },
        false,
        false,
        target,
      ).subscribe((modal) => modal.closingEvent.subscribe(() => {
        if (modal.changed) {
          resolve({ languageClass: modal.languageClass, content: modal.content });
        }
      }));
    });
  }

  /**
   * Show a modal to edit the child pages macro.
   * Used from within ckeditor-augmented-textarea.
   */
  public configureChildPages(page:string, includeParent:string):Promise<object> {
    return new Promise<object>((resolve, _) => {
      this.opModalService.show(
        ChildPagesMacroModalComponent,
        this.injector,
        { page, includeParent },
      ).subscribe((modal) => modal.closingEvent.subscribe(() => {
        if (modal.changed) {
          resolve({
            page: modal.page,
            includeParent: modal.includeParent,
          });
        }
      }));
    });
  }
}
