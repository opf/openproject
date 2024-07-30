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
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  EventEmitter,
  Input,
  OnChanges,
  OnInit,
  Output,
  SimpleChanges,
  ViewChild,
} from '@angular/core';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { IFileIcon } from 'core-app/shared/components/storages/icons.mapping';
import { IFileLink, IFileLinkOriginData } from 'core-app/core/state/file-links/file-link.model';
import {
  fileLinkStatusError, fileLinkStatusNotFound,
  fileLinkViewAllowed,
  fileLinkViewNotAllowed,
} from 'core-app/shared/components/storages/storages-constants.const';
import { PrincipalRendererService } from 'core-app/shared/components/principal/principal-renderer.service';
import { ConfirmDialogOptions } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.modal';
import { ConfirmDialogService } from 'core-app/shared/components/modals/confirm-dialog/confirm-dialog.service';
import { getIconForMimeType, isDirectory } from 'core-app/shared/components/storages/functions/storages.functions';
import { FloatingAction } from 'core-app/shared/components/storages/file-link-list-item/floating-action';
import SpotDropAlignmentOption from 'core-app/spot/drop-alignment-options';

@Component({
  // eslint-disable-next-line @angular-eslint/component-selector
  selector: '[op-file-link-list-item]',
  templateUrl: './file-link-list-item.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class FileLinkListItemComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() public fileLink:IFileLink;

  @Input() public allowEditing = false;

  @Input() public disabled = true;

  @Output() public removeFileLink = new EventEmitter<void>();

  @ViewChild('avatar') avatar:ElementRef;

  infoTimestampText:string;

  fileLinkIcon:IFileIcon;

  floatingActions:FloatingAction[];

  tooltipAlignment:SpotDropAlignmentOption = SpotDropAlignmentOption.TopLeft;

  tooltip:string;

  text = {
    title: {
      openFile: this.i18n.t('js.storages.file_links.open'),
      openFileLocation: this.i18n.t('js.storages.file_links.open_location'),
      removeFileLink: this.i18n.t('js.storages.file_links.remove'),
      downloadFileLink: '',
    },
    removalTitle: this.i18n.t('js.storages.file_links.remove'),
    removalButtonLabel: this.i18n.t('js.storages.file_links.remove_short'),
    removalConfirmation: this.i18n.t('js.storages.file_links.remove_confirmation'),
    notLoggedInTooltipText: this.i18n.t('js.storages.file_links.tooltip.not_logged_in'),
    viewNotAllowedTooltipText: this.i18n.t('js.storages.file_links.tooltip.view_not_allowed'),
    notFoundTooltipText: this.i18n.t('js.storages.file_links.tooltip.not_found'),
  };

  constructor(
    private readonly i18n:I18nService,
    private readonly timezoneService:TimezoneService,
    private readonly confirmDialogService:ConfirmDialogService,
    private readonly principalRendererService:PrincipalRendererService,
  ) {}

  public get hasTooltip():boolean {
    return this.tooltip !== '';
  }

  public get clickable():boolean {
    return !(this.disabled || this.statusIs(fileLinkStatusNotFound));
  }

  public get hasFaultyStatus():boolean {
    return !this.statusIs(fileLinkViewAllowed);
  }

  private get originData():IFileLinkOriginData {
    return this.fileLink.originData;
  }

  ngOnInit():void {
    if (this.originData.lastModifiedAt) {
      this.infoTimestampText = this.timezoneService.parseDatetime(this.originData.lastModifiedAt).fromNow();
    }

    this.fileLinkIcon = getIconForMimeType(this.originData.mimeType);

    this.tooltip = this.toolTipText();

    this.text.title.downloadFileLink = this.i18n.t(
      'js.storages.file_links.download',
      { fileName: this.fileLink.originData.name },
    );
  }

  // Before, the getFloatingActions() method was called in the ngOnInit() method.
  // The value of the allowEditing property can be calculated after the component is already initialized (in fact it is determined
  // asynchronously, by getting a value from the server in a separate request). Therefore, the available actions need
  // to be calculated whenever the value is set.
  ngOnChanges(changes:SimpleChanges):void {
    if (changes.allowEditing) {
      this.floatingActions = this.getFloatingActions();
    }
  }

  ngAfterViewInit():void {
    if (this.originData.lastModifiedByName) {
      this.principalRendererService.render(
        this.avatar.nativeElement as HTMLElement,
        { name: this.originData.lastModifiedByName, href: '/external_users/1' },
        { hide: true, link: false },
        { hide: false, size: 'mini' },
      );
    } else {
      this.principalRendererService.render(
        this.avatar.nativeElement as HTMLElement,
        { name: 'Not Available', href: '/placeholder_users/1' },
        { hide: true, link: false },
        { hide: false, size: 'mini' },
      );
    }
  }

  public confirmRemoveFileLink():void {
    const options:ConfirmDialogOptions = {
      text: {
        text: this.text.removalConfirmation,
        title: this.text.removalTitle,
        button_continue: this.text.removalButtonLabel,
      },
      icon: {
        continue: 'remove-link',
      },
    };
    void this.confirmDialogService
      .confirm(options)
      .then(() => { this.removeFileLink.emit(); })
      .catch(() => { /* confirmation rejected */ });
  }

  private toolTipText():string {
    if (this.disabled) {
      return this.text.notLoggedInTooltipText;
    }

    if (!this.fileLink._links.status) {
      return '';
    }

    switch (this.fileLink._links.status.href) {
      case fileLinkViewNotAllowed:
        return this.text.viewNotAllowedTooltipText;
      case fileLinkStatusError:
        return this.text.notLoggedInTooltipText;
      case fileLinkStatusNotFound:
        return this.text.notFoundTooltipText;
      default:
        return '';
    }
  }

  private statusIs(value:string):boolean {
    return !!this.fileLink._links.status && this.fileLink._links.status.href === value;
  }

  private getFloatingActions():FloatingAction[] {
    if (this.disabled) {
      return [];
    }

    if (this.hasFaultyStatus && this.allowEditing) {
      return [this.removeAction()];
    }

    // healthy file link
    const actions:FloatingAction[] = [];
    if (!isDirectory(this.originData)) {
      actions.push(this.downloadAction());
    }

    actions.push(this.openInLocationAction());

    if (this.allowEditing) {
      actions.push(this.removeAction());
    }

    return actions;
  }

  private removeAction():FloatingAction {
    return new FloatingAction(
      'remove-link',
      this.text.title.removeFileLink,
      () => this.confirmRemoveFileLink(),
    );
  }

  private downloadAction():FloatingAction {
    return new FloatingAction(
      'download-arrow',
      this.text.title.downloadFileLink,
      undefined,
      { url: this.fileLink._links.staticOriginDownload.href, target: '_self' },
    );
  }

  private openInLocationAction():FloatingAction {
    return new FloatingAction(
      'folder-open',
      this.text.title.openFileLocation,
      undefined,
      { url: this.fileLink._links.staticOriginOpenLocation.href, target: '_blank' },
    );
  }
}
