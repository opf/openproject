import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  EventEmitter,
  Input,
  OnInit,
  Output,
} from '@angular/core';
import { uiStateLinkClass } from 'core-app/features/work-packages/components/wp-fast-table/builders/ui-state-link-builder';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { Highlighting } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';
import {
  StateService,
  UIRouterGlobals,
} from '@uirouter/core';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { WorkPackageCardViewService } from 'core-app/features/work-packages/components/wp-card-view/services/wp-card-view.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CardHighlightingMode } from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting-mode.const';
import { CardViewOrientation } from 'core-app/features/work-packages/components/wp-card-view/wp-card-view.component';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { isClickedWithModifier } from 'core-app/shared/helpers/link-handling/link-handling';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { StatusResource } from 'core-app/features/hal/resources/status-resource';
import { combineLatest } from 'rxjs';
import { map } from 'rxjs/operators';

@Component({
  selector: 'wp-single-card',
  styleUrls: ['./wp-single-card.component.sass'],
  templateUrl: './wp-single-card.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageSingleCardComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public workPackage:WorkPackageResource;

  @Input() public selectedWhenOpen = false;

  @Input() public showInfoButton = false;

  @Input() public showStatusButton = true;

  @Input() public showRemoveButton = false;

  @Input() public highlightingMode:CardHighlightingMode = 'inline';

  @Input() public draggable = false;

  @Input() public orientation:CardViewOrientation = 'vertical';

  @Input() public shrinkOnMobile = false;

  @Input() public disabledInfo?:{ text:string, orientation:'left'|'right' };

  @Input() public showAsInlineCard = false;

  @Input() public showStartDate = true;

  @Input() public showEndDate = true;

  @Input() public isClosed = false;

  @Input() public showAsGhost = false;

  @Output() onRemove = new EventEmitter<WorkPackageResource>();

  @Output() stateLinkClicked = new EventEmitter<{ workPackageId:string, requestedState:string }>();

  @Output() cardClicked = new EventEmitter<{ workPackageId:string, event:MouseEvent }>();

  @Output() cardContextMenu = new EventEmitter<{ workPackageId:string, event:MouseEvent }>();

  public uiStateLinkClass:string = uiStateLinkClass;

  public selected = false;

  public text = {
    removeCard: this.I18n.t('js.card.remove_from_list'),
    detailsView: this.I18n.t('js.button_open_details'),
  };

  public isNewResource = isNewResource;

  private dateTimeFormatYear = new Intl.DateTimeFormat(this.I18n.locale, {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  });

  private dateTimeFormat = new Intl.DateTimeFormat(this.I18n.locale, {
    month: 'short',
    day: 'numeric',
  });

  constructor(
    readonly pathHelper:PathHelperService,
    readonly I18n:I18nService,
    readonly $state:StateService,
    readonly uiRouterGlobals:UIRouterGlobals,
    readonly wpTableSelection:WorkPackageViewSelectionService,
    readonly wpTableFocus:WorkPackageViewFocusService,
    readonly cardView:WorkPackageCardViewService,
    readonly cdRef:ChangeDetectorRef,
    readonly timezoneService:TimezoneService,
  ) {
    super();
  }

  ngOnInit():void {
    // Update selection state
    combineLatest([
      this.wpTableSelection.live$(),
      this.uiRouterGlobals.params$,
    ])
      .pipe(
        this.untilDestroyed(),
        map(() => {
          if (this.selectedWhenOpen) {
            return this.uiRouterGlobals.params.workPackageId === this.workPackage.id;
          }

          return this.wpTableSelection.isSelected(this.workPackage.id as string);
        }),
      )
      .subscribe((selected) => {
        this.selected = selected;
        this.cdRef.detectChanges();
      });
  }

  public classIdentifier(wp:WorkPackageResource):string {
    return this.cardView.classIdentifier(wp);
  }

  public emitStateLinkClicked(event:MouseEvent, wp:WorkPackageResource, detail?:boolean):void {
    if (isClickedWithModifier(event)) {
      return;
    }

    const classIdentifier = this.classIdentifier(wp);
    const stateToEmit = detail ? 'split' : 'show';

    this.wpTableSelection.setSelection(wp.id!, this.cardView.findRenderedCard(classIdentifier));
    this.wpTableFocus.updateFocus(wp.id!);
    this.stateLinkClicked.emit({ workPackageId: wp.id!, requestedState: stateToEmit });
    event.preventDefault();
  }

  public cardClasses():{ [className:string]:boolean } {
    const base = 'op-wp-single-card';

    return {
      [`${base}_selected`]: this.selected,
      [`${base}_draggable`]: this.draggable,
      [`${base}_new`]: isNewResource(this.workPackage),
      [`${base}_shrink`]: this.shrinkOnMobile,
      [`${base}_inline`]: this.showAsInlineCard,
      [`${base}_closed`]: this.isClosed,
      [`${base}_ghosted`]: this.showAsGhost,
      // eslint-disable-next-line @typescript-eslint/restrict-template-expressions
      [`${base}-${this.workPackage.id}`]: !!this.workPackage.id,
      [`${base}_${this.orientation}`]: true,
    };
  }

  cardTitle():string {
    return `${this.workPackage.subject} (${(this.workPackage.status as StatusResource).name})`;
  }

  // eslint-disable-next-line class-methods-use-this
  public wpTypeAttribute(wp:WorkPackageResource):string {
    return wp.type.name;
  }

  // eslint-disable-next-line class-methods-use-this
  public wpSubject(wp:WorkPackageResource):string {
    return wp.subject;
  }

  // eslint-disable-next-line class-methods-use-this
  public wpProjectName(wp:WorkPackageResource):string {
    return wp.project?.name;
  }

  public wpDates(wp:WorkPackageResource):string {
    const { startDate, dueDate } = wp;

    if (startDate && dueDate) {
      // eslint-disable-next-line @typescript-eslint/ban-ts-comment
      // @ts-ignore see https://github.com/microsoft/TypeScript/issues/46905
      // eslint-disable-next-line @typescript-eslint/no-unsafe-call
      return String(this.dateTimeFormatYear.formatRange(new Date(startDate), new Date(dueDate)));
    }

    if (!startDate && dueDate) {
      return `– ${this.dateTimeFormatYear.format(new Date(dueDate))}`;
    }

    if (startDate && !dueDate) {
      return `${this.dateTimeFormatYear.format(new Date(startDate))} –`;
    }

    return '';
  }

  startDate(wp:WorkPackageResource):string {
    const { startDate } = wp;
    if (!startDate) {
      return '';
    }

    return this.dateTimeFormat.format(new Date(startDate));
  }

  endDate(wp:WorkPackageResource):string {
    const { dueDate } = wp;
    if (!dueDate) {
      return '';
    }

    return this.dateTimeFormat.format(new Date(dueDate));
  }

  wpOverDueHighlighting(wp:WorkPackageResource):string {
    const diff = this.timezoneService.daysFromToday(wp.dueDate);
    return Highlighting.overdueDate(diff);
  }

  public fullWorkPackageLink(wp:WorkPackageResource):string {
    return this.$state.href('work-packages.show', { workPackageId: wp.id });
  }

  public cardHighlightingClass(wp:WorkPackageResource):string {
    return this.cardHighlighting(wp);
  }

  public typeHighlightingClass(wp:WorkPackageResource):string {
    return this.attributeHighlighting('type', wp);
  }

  public onRemoved(wp:WorkPackageResource):void {
    this.onRemove.emit(wp);
  }

  public cardCoverImageShown(wp:WorkPackageResource):boolean {
    return this.bcfSnapshotPath(wp) !== null;
  }

  // eslint-disable-next-line class-methods-use-this
  public bcfSnapshotPath(wp:WorkPackageResource):string|null {
    return wp.bcfViewpoints && wp.bcfViewpoints.length > 0 ? `${wp.bcfViewpoints[0].href}/snapshot` : null;
  }

  private cardHighlighting(wp:WorkPackageResource):string {
    if (['status', 'priority', 'type'].includes(this.highlightingMode)) {
      return Highlighting.backgroundClass(this.highlightingMode, wp[this.highlightingMode].id);
    }
    return '';
  }

  // eslint-disable-next-line class-methods-use-this
  private attributeHighlighting(type:string, wp:WorkPackageResource):string {
    return Highlighting.inlineClass(type, wp.type.id!);
  }
}
