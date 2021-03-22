import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  EventEmitter,
  Input,
  OnInit,
  Output
} from "@angular/core";
import { WorkPackageResource } from "core-app/modules/hal/resources/work-package-resource";
import { checkedClassName, uiStateLinkClass } from "core-components/wp-fast-table/builders/ui-state-link-builder";
import { PathHelperService } from "core-app/modules/common/path-helper/path-helper.service";
import { Highlighting } from "core-components/wp-fast-table/builders/highlighting/highlighting.functions";
import { StateService } from "@uirouter/core";
import { WorkPackageViewSelectionService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-selection.service";
import { WorkPackageCardViewService } from "core-components/wp-card-view/services/wp-card-view.service";
import { I18nService } from "core-app/modules/common/i18n/i18n.service";
import { CardHighlightingMode } from "core-components/wp-fast-table/builders/highlighting/highlighting-mode.const";
import { CardViewOrientation } from "core-components/wp-card-view/wp-card-view.component";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { WorkPackageViewFocusService } from "core-app/modules/work_packages/routing/wp-view-base/view-services/wp-view-focus.service";
import { splitViewRoute } from "core-app/modules/work_packages/routing/split-view-routes.helper";

@Component({
  selector: 'wp-single-card',
  styleUrls: ['./wp-single-card.component.sass'],
  templateUrl: './wp-single-card.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class WorkPackageSingleCardComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public workPackage:WorkPackageResource;
  @Input() public showInfoButton = false;
  @Input() public showStatusButton = true;
  @Input() public showRemoveButton = false;
  @Input() public highlightingMode:CardHighlightingMode = 'inline';
  @Input() public draggable = false;
  @Input() public orientation:CardViewOrientation = 'vertical';
  @Input() public shrinkOnMobile = false;

  @Output() onRemove = new EventEmitter<WorkPackageResource>();
  @Output() stateLinkClicked = new EventEmitter<{ workPackageId:string, requestedState:string }>();

  public uiStateLinkClass:string = uiStateLinkClass;

  public text = {
    removeCard: this.I18n.t('js.card.remove_from_list'),
    detailsView: this.I18n.t('js.button_open_details')
  };

  constructor(readonly pathHelper:PathHelperService,
              readonly I18n:I18nService,
              readonly $state:StateService,
              readonly wpTableSelection:WorkPackageViewSelectionService,
              readonly wpTableFocus:WorkPackageViewFocusService,
              readonly cardView:WorkPackageCardViewService,
              readonly cdRef:ChangeDetectorRef) {
    super();
  }

  ngOnInit():void {
    // Update selection state
    this.wpTableSelection.live$()
      .pipe(
        this.untilDestroyed()
      )
      .subscribe(() => {
        this.cdRef.detectChanges();
      });
  }

  public classIdentifier(wp:WorkPackageResource) {
    return this.cardView.classIdentifier(wp);
  }

  public emitStateLinkClicked(wp:WorkPackageResource, detail?:boolean) {
    const classIdentifier = this.classIdentifier(wp);
    const stateToEmit = detail ? splitViewRoute(this.$state) : 'work-packages.show';

    this.wpTableSelection.setSelection(wp.id!, this.cardView.findRenderedCard(classIdentifier));
    this.wpTableFocus.updateFocus(wp.id!);
    this.stateLinkClicked.emit({ workPackageId:wp.id!, requestedState: stateToEmit });
  }

  public cardClasses() {
    let classes = this.isSelected(this.workPackage) ? checkedClassName : '';
    classes += this.draggable ? ' -draggable' : '';
    classes += this.workPackage.isNew ? ' -new' : '';
    classes += ' wp-card-' + this.workPackage.id;
    classes += ' -' + this.orientation;
    classes += this.shrinkOnMobile ? ' -shrink' : '';
    return classes;
  }

  public wpTypeAttribute(wp:WorkPackageResource) {
    return wp.type.name;
  }

  public wpSubject(wp:WorkPackageResource) {
    return wp.subject;
  }

  public wpProjectName(wp:WorkPackageResource) {
    return wp.project?.name;
  }

  public fullWorkPackageLink(wp:WorkPackageResource) {
    return this.$state.href('work-packages.show', { workPackageId: wp.id });
  }

  public cardHighlightingClass(wp:WorkPackageResource) {
    return this.cardHighlighting(wp);
  }

  public typeHighlightingClass(wp:WorkPackageResource) {
    return this.attributeHighlighting('type', wp);
  }

  public onRemoved(wp:WorkPackageResource) {
    this.onRemove.emit(wp);
  }

  public cardCoverImageShown(wp:WorkPackageResource):boolean {
    return this.bcfSnapshotPath(wp) !== null;
  }

  public bcfSnapshotPath(wp:WorkPackageResource) {
    return wp.bcfViewpoints && wp.bcfViewpoints.length > 0 ? wp.bcfViewpoints[0].href + '/snapshot' : null;
  }

  private isSelected(wp:WorkPackageResource):boolean {
    return this.wpTableSelection.isSelected(wp.id!);
  }

  private cardHighlighting(wp:WorkPackageResource) {
    if (['status', 'priority', 'type'].includes(this.highlightingMode)) {
      return Highlighting.backgroundClass(this.highlightingMode, wp[this.highlightingMode].id);
    }
    return '';
  }

  private attributeHighlighting(type:string, wp:WorkPackageResource) {
    return Highlighting.inlineClass(type, wp.type.id!);
  }
}
