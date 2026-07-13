import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  EventEmitter, inject,
  Input,
  OnInit,
  Output,
} from '@angular/core';
import {
  uiStateLinkClass,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/ui-state-link-builder';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import {
  Highlighting,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting.functions';
import { StateService, UIRouterGlobals } from '@uirouter/core';
import {
  WorkPackageViewSelectionService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import {
  WorkPackageCardViewService,
} from 'core-app/features/work-packages/components/wp-card-view/services/wp-card-view.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  CardHighlightingMode,
} from 'core-app/features/work-packages/components/wp-fast-table/builders/highlighting/highlighting-mode.const';
import { CardViewOrientation } from 'core-app/features/work-packages/components/wp-card-view/wp-card-view.component';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import {
  WorkPackageViewFocusService,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { isClickedWithModifier } from 'core-app/shared/helpers/link-handling/link-handling';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { StatusResource } from 'core-app/features/hal/resources/status-resource';
import { EMPTY, fromEvent, merge } from 'rxjs';
import { distinctUntilChanged, map } from 'rxjs/operators';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import SpotDropAlignmentOption from 'core-app/spot/drop-alignment-options';
import { BaselineMode, getBaselineState } from 'core-app/features/work-packages/components/wp-baseline/baseline-helpers';
import {
  CombinedDateDisplayField,
} from 'core-app/shared/components/fields/display/field-types/combined-date-display.field';
import {
  KeepTabService
} from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { WP_ID_URL_PATTERN } from 'core-app/shared/helpers/work-package-id-pattern';
import { matchesRoutingId } from 'core-app/features/work-packages/helpers/work-package-id-resolvers';

const DETAILS_URL_PATTERN = new RegExp(`/details/(${WP_ID_URL_PATTERN})(?:/|$)`);

@Component({
  selector: 'wp-single-card',
  styleUrls: ['./wp-single-card.component.sass'],
  templateUrl: './wp-single-card.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
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

  @Output() cardDblClicked = new EventEmitter<{ workPackageId:string, event:MouseEvent }>();

  @Output() cardContextMenu = new EventEmitter<{ workPackageId:string, event:MouseEvent }>();

  readonly pathHelper = inject(PathHelperService);
  readonly I18n = inject(I18nService);
  readonly $state = inject(StateService);
  readonly uiRouterGlobals = inject(UIRouterGlobals);
  readonly wpTableSelection = inject(WorkPackageViewSelectionService);
  readonly wpTableFocus = inject(WorkPackageViewFocusService);
  readonly cardView = inject(WorkPackageCardViewService);
  readonly cdRef = inject(ChangeDetectorRef);
  readonly timezoneService = inject(TimezoneService);
  readonly schemaCache = inject(SchemaCacheService);
  readonly keepTabService = inject(KeepTabService);

  public uiStateLinkClass:string = uiStateLinkClass;

  public selected = false;

  public baselineMode:BaselineMode;

  public text = {
    removeCard: this.I18n.t('js.card.remove_from_list'),
    detailsView: this.I18n.t('js.button_open_details'),
    baseLineIconAdded: this.I18n.t('js.baseline.icon_tooltip.added'),
    baseLineIconChanged: this.I18n.t('js.baseline.icon_tooltip.changed'),
    baseLineIconRemoved: this.I18n.t('js.baseline.icon_tooltip.removed'),
    assigneeAlt:(assignee:string) =>
      this.I18n.t('js.label_assignee_alt_text', { name: assignee }),
  };

  public isNewResource = isNewResource;

  public tooltipPosition = SpotDropAlignmentOption.BottomLeft;

  combinedDateDisplayField = CombinedDateDisplayField;

  ngOnInit():void {
    // Update selection state
    // Use merge instead of combineLatest: params$ only emits on uiRouter transitions and
    // may never emit on pages that don't use uiRouter (e.g. boards). With merge, any
    // emission from either source triggers re-evaluation of the selection state.
    // turbo:frame-load is included so that URL-based detection updates when the split
    // view opens or closes via Turbo frame navigation.
    merge(
      this.wpTableSelection.live$(),
      this.uiRouterGlobals.params$ ?? EMPTY,
      fromEvent(document, 'turbo:frame-load'),
    )
      .pipe(
        this.untilDestroyed(),
        map(() => {
          if (this.selectedWhenOpen) {
            // In uiRouter views, use the route param directly.
            const wpIdFromRoute = this.uiRouterGlobals.params.workPackageId as string|undefined;
            if (wpIdFromRoute) {
              return matchesRoutingId(this.workPackage, wpIdFromRoute);
            }

            // In non-router views (e.g. Team Planner, Calendar):
            // Use URL-based detection so that closing the split view (which changes the URL
            // but does not clear the selection service) correctly deselects the card.
            const urlMatch = DETAILS_URL_PATTERN.exec(window.location.pathname);
            return matchesRoutingId(this.workPackage, urlMatch?.[1]);
          }

          return this.wpTableSelection.isSelected(this.workPackage.id!);
        }),
        distinctUntilChanged(),
      )
      .subscribe((selected:boolean) => {
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

  public cardClasses():Record<string, boolean> {
    const base = 'op-wp-single-card';

    return {
      [`${base}_selected`]: this.selected,
      [`${base}_draggable`]: this.draggable,
      [`${base}_new`]: isNewResource(this.workPackage),
      [`${base}_shrink`]: this.shrinkOnMobile,
      [`${base}_inline`]: this.showAsInlineCard,
      [`${base}_closed`]: this.isClosed,
      [`${base}_ghosted`]: this.showAsGhost,
      [`${base}-${this.workPackage.id}`]: !!this.workPackage.id,
      [`${base}_${this.orientation}`]: true,
    };
  }

  cardTitle():string {
    return `${this.workPackage.subject} (${(this.workPackage.status as StatusResource).name})`;
  }

  public baselineIcon(workPackage:WorkPackageResource) {
    this.baselineMode = getBaselineState(workPackage, this.schemaCache);
    return this.baselineMode;
  }

  public wpTypeAttribute(wp:WorkPackageResource):string {
    return wp.type.name;
  }

  public wpSubject(wp:WorkPackageResource):string {
    return wp.subject;
  }

  public wpProjectName(wp:WorkPackageResource):string {
    return wp.project?.name;
  }

  public fullWorkPackageLink(wp:WorkPackageResource):string {
    return this.keepTabService.currentShowHref(wp.displayId);
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

  public bcfSnapshotPath(wp:WorkPackageResource):string|null {
    return wp.bcfViewpoints && wp.bcfViewpoints.length > 0 ? `${wp.bcfViewpoints[0].href}/snapshot` : null;
  }

  private cardHighlighting(wp:WorkPackageResource):string {
    if (['status', 'priority', 'type'].includes(this.highlightingMode)) {
      return Highlighting.backgroundClass(this.highlightingMode, wp[this.highlightingMode].id);
    }
    return '';
  }

  private attributeHighlighting(type:string, wp:WorkPackageResource):string {
    return Highlighting.inlineClass(type, wp.type.id!);
  }
}
