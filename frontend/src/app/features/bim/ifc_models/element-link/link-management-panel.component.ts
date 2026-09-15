import { Component, Input, OnInit, OnDestroy, Output, EventEmitter } from '@angular/core';
import { Subject } from 'rxjs';
import { takeUntil } from 'rxjs/operators';
import { ElementLinkManager, ElementLink, RelationshipType, LinkStatus } from './element-link-manager.service';
import { BulkLinkOperationsService, LinkTemplate } from './bulk-link-operations.service';

/**
 * LinkManagementPanel Component
 *
 * Main UI component for managing element-to-work-package links in the BIM viewer.
 * Provides:
 * - Link creation and management
 * - Template application
 * - Bulk operations
 * - Statistics display
 * - Element selection mode
 */
@Component({
  selector: 'op-link-management-panel',
  templateUrl: './link-management-panel.component.html',
  styleUrls: ['./link-management-panel.component.scss']
})
export class LinkManagementPanelComponent implements OnInit, OnDestroy {
  @Input() workPackageId!: number;
  @Input() ifcModelId!: number;
  @Input() viewer: any; // xeokit viewer instance

  @Output() linkCreated = new EventEmitter<ElementLink>();
  @Output() linkDeleted = new EventEmitter<number>();
  @Output() selectionModeChanged = new EventEmitter<boolean>();

  // Component state
  links: ElementLink[] = [];
  templates: LinkTemplate[] = [];
  selectedTemplate?: LinkTemplate;
  selectedRelationshipType: RelationshipType = 'affected_by';
  isLoading = false;
  isSelectionMode = false;
  selectedElementIds: string[] = [];

  // Filters
  filterStatus: LinkStatus | 'all' = 'all';
  filterRelationshipType: RelationshipType | 'all' = 'all';
  searchQuery = '';

  // Statistics
  statistics = {
    total: 0,
    by_type: {} as Record<string, number>,
    by_relationship: {} as Record<RelationshipType, number>,
    by_status: {} as Record<LinkStatus, number>
  };

  // UI state
  showTemplateSelector = false;
  showBulkActions = false;
  activeTab: 'links' | 'templates' | 'statistics' = 'links';

  private destroy$ = new Subject<void>();

  // Relationship type options
  relationshipTypes: Array<{ value: RelationshipType; label: string; color: string }> = [
    { value: 'affected_by', label: 'Affected By', color: '#ff0000' },
    { value: 'responsible_for', label: 'Responsible For', color: '#00ff00' },
    { value: 'depends_on', label: 'Depends On', color: '#0000ff' },
    { value: 'observes', label: 'Observes', color: '#ffff00' },
    { value: 'related_to', label: 'Related To', color: '#808080' }
  ];

  constructor(
    private linkManager: ElementLinkManager,
    private bulkOperations: BulkLinkOperationsService
  ) {}

  ngOnInit(): void {
    this.loadLinks();
    this.loadTemplates();
    this.updateStatistics();
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
    if (this.isSelectionMode) {
      this.exitSelectionMode();
    }
  }

  /**
   * Load links for the current work package
   */
  loadLinks(): void {
    this.isLoading = true;
    this.linkManager.getLinksForWorkPackage(this.workPackageId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (links) => {
          this.links = links;
          this.isLoading = false;
          this.updateStatistics();
        },
        error: (error) => {
          console.error('Failed to load links:', error);
          this.isLoading = false;
        }
      });
  }

  /**
   * Load available templates
   */
  loadTemplates(): void {
    this.bulkOperations.getTemplates()
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (templates) => {
          this.templates = templates;
        },
        error: (error) => {
          console.error('Failed to load templates:', error);
        }
      });
  }

  /**
   * Update statistics
   */
  updateStatistics(): void {
    this.statistics = this.linkManager.getElementStatistics(this.workPackageId);
  }

  /**
   * Enter element selection mode
   */
  enterSelectionMode(): void {
    this.isSelectionMode = true;
    this.selectedElementIds = [];
    this.linkManager.startLinkingMode(this.workPackageId, this.selectedRelationshipType);
    this.selectionModeChanged.emit(true);
  }

  /**
   * Exit element selection mode
   */
  exitSelectionMode(): void {
    this.isSelectionMode = false;
    this.selectedElementIds = [];
    this.linkManager.stopLinkingMode();
    this.selectionModeChanged.emit(false);
  }

  /**
   * Toggle element selection
   */
  onElementClicked(elementId: string): void {
    if (!this.isSelectionMode) return;

    this.linkManager.toggleElementSelection(elementId);

    const index = this.selectedElementIds.indexOf(elementId);
    if (index > -1) {
      this.selectedElementIds.splice(index, 1);
    } else {
      this.selectedElementIds.push(elementId);
    }
  }

  /**
   * Create links from selected elements
   */
  createLinksFromSelection(): void {
    if (this.selectedElementIds.length === 0) return;

    this.isLoading = true;
    this.linkManager.createLinksFromSelection(
      this.workPackageId,
      this.selectedRelationshipType
    )
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (links) => {
          this.links.push(...links);
          this.exitSelectionMode();
          this.updateStatistics();
          this.isLoading = false;
          links.forEach(link => this.linkCreated.emit(link));
        },
        error: (error) => {
          console.error('Failed to create links:', error);
          this.isLoading = false;
        }
      });
  }

  /**
   * Apply template
   */
  applyTemplate(template: LinkTemplate, dryRun = false): void {
    this.isLoading = true;
    this.bulkOperations.applyTemplate({
      work_package_id: this.workPackageId,
      ifc_model_id: this.ifcModelId,
      template_id: template.id,
      dry_run: dryRun
    })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (dryRun) {
            alert(`Template would create ${response.count} links`);
          } else {
            this.loadLinks();
          }
          this.isLoading = false;
        },
        error: (error) => {
          console.error('Failed to apply template:', error);
          this.isLoading = false;
        }
      });
  }

  /**
   * Delete a link
   */
  deleteLink(linkId: number): void {
    if (!confirm('Are you sure you want to delete this link?')) return;

    this.linkManager.removeLink(linkId)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.links = this.links.filter(link => link.id !== linkId);
          this.updateStatistics();
          this.linkDeleted.emit(linkId);
        },
        error: (error) => {
          console.error('Failed to delete link:', error);
        }
      });
  }

  /**
   * Update link status
   */
  updateLinkStatus(linkId: number, newStatus: LinkStatus): void {
    this.linkManager.updateLinkStatus(linkId, newStatus)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (updatedLink) => {
          const index = this.links.findIndex(link => link.id === linkId);
          if (index > -1) {
            this.links[index] = updatedLink;
            this.updateStatistics();
          }
        },
        error: (error) => {
          console.error('Failed to update link status:', error);
        }
      });
  }

  /**
   * Visualize links in viewer
   */
  visualizeLinks(relationshipType?: RelationshipType): void {
    const linksToVisualize = relationshipType
      ? this.links.filter(link => link.relationship_type === relationshipType)
      : this.links;

    this.linkManager.visualizeLinks(linksToVisualize, relationshipType);
  }

  /**
   * Clear visualization
   */
  clearVisualization(): void {
    this.linkManager.clearVisualization();
  }

  /**
   * Get filtered links
   */
  get filteredLinks(): ElementLink[] {
    let filtered = this.links;

    // Filter by status
    if (this.filterStatus !== 'all') {
      filtered = filtered.filter(link => link.status === this.filterStatus);
    }

    // Filter by relationship type
    if (this.filterRelationshipType !== 'all') {
      filtered = filtered.filter(link => link.relationship_type === this.filterRelationshipType);
    }

    // Filter by search query
    if (this.searchQuery) {
      const query = this.searchQuery.toLowerCase();
      filtered = filtered.filter(link =>
        link.element_id.toLowerCase().includes(query)
      );
    }

    return filtered;
  }

  /**
   * Bulk complete selected links
   */
  bulkCompleteLinks(): void {
    const activeLinks = this.links.filter(link => link.status === 'active');
    if (activeLinks.length === 0) return;

    if (!confirm(`Complete ${activeLinks.length} active links?`)) return;

    this.isLoading = true;
    this.bulkOperations.bulkStatusChange({
      link_ids: activeLinks.map(link => link.id),
      new_status: 'completed'
    })
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: () => {
          this.loadLinks();
          this.isLoading = false;
        },
        error: (error) => {
          console.error('Failed to complete links:', error);
          this.isLoading = false;
        }
      });
  }

  /**
   * Refresh element properties
   */
  refreshProperties(): void {
    const linkIds = this.links.map(link => link.id);
    if (linkIds.length === 0) return;

    this.isLoading = true;
    this.bulkOperations.refreshElementProperties(linkIds)
      .pipe(takeUntil(this.destroy$))
      .subscribe({
        next: (response) => {
          if (response.changed_count > 0) {
            alert(`${response.changed_count} elements have changed`);
            this.loadLinks();
          } else {
            alert('No elements have changed');
          }
          this.isLoading = false;
        },
        error: (error) => {
          console.error('Failed to refresh properties:', error);
          this.isLoading = false;
        }
      });
  }

  /**
   * Get relationship type label
   */
  getRelationshipLabel(type: RelationshipType): string {
    return this.relationshipTypes.find(rt => rt.value === type)?.label || type;
  }

  /**
   * Get relationship type color
   */
  getRelationshipColor(type: RelationshipType): string {
    return this.relationshipTypes.find(rt => rt.value === type)?.color || '#808080';
  }

  /**
   * Track by function for ngFor
   */
  trackByLinkId(index: number, link: ElementLink): number {
    return link.id;
  }

  /**
   * Track by function for templates
   */
  trackByTemplateId(index: number, template: LinkTemplate): number {
    return template.id;
  }

  /**
   * Helper to get object keys for ngFor
   */
  objectKeys(obj: any): string[] {
    return obj ? Object.keys(obj) : [];
  }
}
