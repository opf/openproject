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

import copy from 'copy-text-to-clipboard';
import {
  Component,
  Inject,
  Input,
} from '@angular/core';
import { GitActionsService } from '../git-actions/git-actions.service';
import { WorkPackageResource } from "core-app/features/hal/resources/work-package-resource";
import { OPContextMenuComponent } from "core-app/shared/components/op-context-menu/op-context-menu.component";
import {
  OpContextMenuLocalsMap,
  OpContextMenuLocalsToken,
} from "core-app/shared/components/op-context-menu/op-context-menu.types";
import { I18nService } from "core-app/core/i18n/i18n.service";
import { ISnippet } from 'core-app/features/plugins/linked/openproject-github_integration/state/github-pull-request.model';


@Component({
  selector: 'op-git-actions-menu',
  templateUrl: './git-actions-menu.template.html',
  styleUrls: [
    './styles/git-actions-menu.sass',
  ],
})
export class GitActionsMenuComponent extends OPContextMenuComponent {
  @Input() public workPackage:WorkPackageResource;

  public text = {
    title: this.I18n.t('js.github_integration.tab_header.git_actions.title'),
    copyButtonHelpText: this.I18n.t('js.github_integration.tab_header.git_actions.copy_button_help'),
    copyResult: {
      success: this.I18n.t('js.github_integration.tab_header.git_actions.copy_success'),
      error: this.I18n.t('js.github_integration.tab_header.git_actions.copy_error'),
    },
  };

  public lastCopyResult:string = this.text.copyResult.success;

  public showCopyResult:boolean = false;

  public copiedSnippetId:string = '';

  public snippets:ISnippet[] = [
    {
      id: 'branch',
      name: this.I18n.t('js.github_integration.tab_header.git_actions.branch_name'),
      textToDisplay: () => this.gitActions.branchName(this.workPackage),
      textToCopy: () => this.gitActions.branchName(this.workPackage),
    },
    {
      id: 'message',
      name: this.I18n.t('js.github_integration.tab_header.git_actions.commit_message'),
      textToDisplay: () => this.gitActions.commitMessageDisplayText(this.workPackage),
      textToCopy: () => this.gitActions.commitMessage(this.workPackage),
    },
    {
      id: 'command',
      name: this.I18n.t('js.github_integration.tab_header.git_actions.cmd'),
      textToDisplay: () => this.gitActions.gitCommand(this.workPackage),
      textToCopy: () => this.gitActions.gitCommand(this.workPackage),
    },
  ];

  constructor(
    @Inject(OpContextMenuLocalsToken)
    public locals:OpContextMenuLocalsMap,
    readonly I18n:I18nService,
    readonly gitActions:GitActionsService,
  ) {
    super(locals);
    this.workPackage = this.locals.workPackage as WorkPackageResource;
  }

  public onCopyButtonClick(snippet:ISnippet):void {
    const success = copy(snippet.textToCopy());

    if (success) {
      this.lastCopyResult = this.text.copyResult.success;
    } else {
      this.lastCopyResult = this.text.copyResult.error;
    }
    this.copiedSnippetId = snippet.id;
    this.showCopyResult = true;
    window.setTimeout(() => {
      this.showCopyResult = false;
    }, 2000);
  }
}
