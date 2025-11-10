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
  Input,
  Output,
  EventEmitter,
  OnInit,
  OnDestroy,
  ChangeDetectorRef,
  ChangeDetectionStrategy,
} from '@angular/core';
import { Subject, Subscription } from 'rxjs';
import { debounceTime, distinctUntilChanged, switchMap } from 'rxjs/operators';
import { V97ApiService, ModelTreeNode, TreeViewMode, ModelTreeSearchResult } from '../services/v9-7-api.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';

/**
 * Model Tree Component (V9.7 UX/UI Polish)
 *
 * Enhanced hierarchical tree view for IFC models with:
 * - 3 view modes: Spatial (hierarchy), Type (grouped), Discipline (grouped)
 * - Lazy loading for performance (10,000+ elements)
 * - Search with debouncing (300ms)
 * - Filter by type, level, discipline
 * - Selection sync with xeokit viewer
 * - Keyboard navigation (Arrow keys, Enter, Space)
 *
 * Usage:
 *   <op-model-tree
 *     [ifcModelId]="123"
 *     [viewMode]="'spatial'"
 *     (nodeSelected)="onNodeSelected($event)"
 *     (nodeToggled)="onNodeToggled($event)">
 *   </op-model-tree>
 */

interface TreeNodeState extends ModelTreeNode {
  expanded: boolean;
  selected: boolean;
  loading: boolean;
  level: number;
  parent?: TreeNodeState;
  children?: TreeNodeState[];
}

@Component({
  selector: 'op-model-tree',
  templateUrl: './model-tree.component.html',
  styleUrls: ['./model-tree.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class ModelTreeComponent implements OnInit, OnDestroy {
  @Input() ifcModelId!: number;

  @Input() viewMode: TreeViewMode = 'spatial';

  @Input() enableSearch = true;

  @Input() enableFilters = true;

  @Output() nodeSelected = new EventEmitter<ModelTreeNode>();

  @Output() nodeToggled = new EventEmitter<{ node: ModelTreeNode; visible: boolean }>();

  @Output() nodesIsolated = new EventEmitter<ModelTreeNode[]>();

  // Tree state
  rootNodes: TreeNodeState[] = [];

  flattenedNodes: TreeNodeState[] = [];

  selectedNode: TreeNodeState | null = null;

  loading = true;

  error: string | null = null;

  // Search state
  searchQuery = '';

  searchResults: ModelTreeSearchResult | null = null;

  searchActive = false;

  private searchSubject = new Subject<string>();

  private searchSubscription?: Subscription;

  // Filter state
  typeFilters: string[] = [];

  levelFilters: string[] = [];

  disciplineFilters: string[] = [];

  availableTypes: string[] = [];

  availableLevels: string[] = [];

  availableDisciplines: string[] = ['Architecture', 'Structure', 'MEP', 'Civil'];

  // i18n text
  text = {
    view_mode_spatial: this.I18n.t('js.bim.model_tree.view_mode_spatial'),
    view_mode_type: this.I18n.t('js.bim.model_tree.view_mode_type'),
    view_mode_discipline: this.I18n.t('js.bim.model_tree.view_mode_discipline'),
    search_placeholder: this.I18n.t('js.bim.model_tree.search_placeholder'),
    loading: this.I18n.t('js.bim.model_tree.loading'),
    no_results: this.I18n.t('js.bim.model_tree.no_results'),
    filter_by_type: this.I18n.t('js.bim.model_tree.filter_by_type'),
    filter_by_level: this.I18n.t('js.bim.model_tree.filter_by_level'),
    filter_by_discipline: this.I18n.t('js.bim.model_tree.filter_by_discipline'),
    clear_filters: this.I18n.t('js.bim.model_tree.clear_filters'),
  };

  constructor(
    private apiService: V97ApiService,
    private I18n: I18nService,
    private cdr: ChangeDetectorRef,
  ) {}

  ngOnInit(): void {
    this.loadRootNodes();
    this.setupSearch();
  }

  ngOnDestroy(): void {
    this.searchSubscription?.unsubscribe();
  }

  // ==================== TREE LOADING ====================

  /**
   * Load root nodes from API
   */
  private loadRootNodes(): void {
    this.loading = true;
    this.error = null;

    this.apiService.getTreeRoot(this.ifcModelId, this.viewMode).subscribe({
      next: (nodes) => {
        this.rootNodes = nodes.map((node) => this.createTreeNodeState(node, 0));
        this.updateFlattenedNodes();
        this.extractAvailableFilters();
        this.loading = false;
        this.cdr.markForCheck();
      },
      error: (err) => {
        this.error = err.message || 'Failed to load tree';
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  /**
   * Load children for a node (lazy loading)
   */
  loadChildren(node: TreeNodeState): void {
    if (!node.has_children || node.children) {
      return; // Already loaded or no children
    }

    node.loading = true;
    this.cdr.markForCheck();

    this.apiService.getTreeChildren(this.ifcModelId, node.id, this.viewMode).subscribe({
      next: (children) => {
        node.children = children.map((child) => this.createTreeNodeState(child, node.level + 1, node));
        node.loading = false;
        this.updateFlattenedNodes();
        this.cdr.markForCheck();
      },
      error: (err) => {
        console.error('Failed to load children:', err);
        node.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  /**
   * Create tree node state object
   */
  private createTreeNodeState(node: ModelTreeNode, level: number, parent?: TreeNodeState): TreeNodeState {
    return {
      ...node,
      expanded: false,
      selected: false,
      loading: false,
      level,
      parent,
      children: undefined,
    };
  }

  /**
   * Update flattened nodes array for rendering
   */
  private updateFlattenedNodes(): void {
    this.flattenedNodes = [];
    this.rootNodes.forEach((node) => this.flattenNode(node));
  }

  /**
   * Recursively flatten tree for rendering
   */
  private flattenNode(node: TreeNodeState): void {
    this.flattenedNodes.push(node);
    if (node.expanded && node.children) {
      node.children.forEach((child) => this.flattenNode(child));
    }
  }

  // ==================== USER INTERACTIONS ====================

  /**
   * Toggle node expansion
   */
  toggleExpand(node: TreeNodeState): void {
    if (!node.has_children) {
      return;
    }

    node.expanded = !node.expanded;

    if (node.expanded && !node.children) {
      this.loadChildren(node);
    } else {
      this.updateFlattenedNodes();
      this.cdr.markForCheck();
    }
  }

  /**
   * Select a node
   */
  selectNode(node: TreeNodeState): void {
    // Deselect previous
    if (this.selectedNode) {
      this.selectedNode.selected = false;
    }

    // Select new
    node.selected = true;
    this.selectedNode = node;

    // Emit event
    this.nodeSelected.emit(node);
    this.cdr.markForCheck();
  }

  /**
   * Toggle node visibility (checkbox)
   */
  toggleVisibility(node: TreeNodeState, event: Event): void {
    event.stopPropagation();
    // For now, just emit event - visibility service will handle the actual toggle
    this.nodeToggled.emit({ node, visible: (event.target as HTMLInputElement).checked });
  }

  /**
   * Isolate node (context menu action)
   */
  isolateNode(node: TreeNodeState): void {
    this.nodesIsolated.emit([node]);
  }

  // ==================== VIEW MODE ====================

  /**
   * Change view mode
   */
  changeViewMode(mode: TreeViewMode): void {
    if (this.viewMode === mode) {
      return;
    }

    this.viewMode = mode;
    this.rootNodes = [];
    this.flattenedNodes = [];
    this.selectedNode = null;
    this.loadRootNodes();
  }

  // ==================== SEARCH ====================

  /**
   * Setup search with debouncing
   */
  private setupSearch(): void {
    this.searchSubscription = this.searchSubject
      .pipe(
        debounceTime(300),
        distinctUntilChanged(),
        switchMap((query) => {
          if (!query || query.length < 2) {
            this.searchActive = false;
            this.searchResults = null;
            this.cdr.markForCheck();
            return [];
          }

          this.searchActive = true;
          this.cdr.markForCheck();

          return this.apiService.searchTree(this.ifcModelId, query, {
            types: this.typeFilters.length > 0 ? this.typeFilters : undefined,
            levels: this.levelFilters.length > 0 ? this.levelFilters : undefined,
            disciplines: this.disciplineFilters.length > 0 ? this.disciplineFilters : undefined,
          });
        }),
      )
      .subscribe({
        next: (results) => {
          if (results) {
            this.searchResults = results;
            this.cdr.markForCheck();
          }
        },
        error: (err) => {
          console.error('Search failed:', err);
          this.searchActive = false;
          this.cdr.markForCheck();
        },
      });
  }

  /**
   * Handle search input change
   */
  onSearchInput(event: Event): void {
    const query = (event.target as HTMLInputElement).value;
    this.searchQuery = query;
    this.searchSubject.next(query);
  }

  /**
   * Clear search
   */
  clearSearch(): void {
    this.searchQuery = '';
    this.searchActive = false;
    this.searchResults = null;
    this.cdr.markForCheck();
  }

  /**
   * Select search result
   */
  selectSearchResult(result: any): void {
    // Find the node in tree and expand path to it
    // For now, just emit the GUID for the viewer to highlight
    this.nodeSelected.emit({
      id: result.guid,
      type: 'element',
      name: result.name,
      guid: result.guid,
      ifc_type: result.ifc_type,
      children_count: 0,
      has_children: false,
      _links: result._links,
    });
  }

  // ==================== FILTERS ====================

  /**
   * Extract available filter options from loaded nodes
   */
  private extractAvailableFilters(): void {
    const types = new Set<string>();
    const levels = new Set<string>();

    const extractFromNode = (node: TreeNodeState) => {
      if (node.ifc_type) types.add(node.ifc_type);
      if (node.level) levels.add(node.level);
      if (node.children) {
        node.children.forEach(extractFromNode);
      }
    };

    this.rootNodes.forEach(extractFromNode);

    this.availableTypes = Array.from(types).sort();
    this.availableLevels = Array.from(levels).sort();
  }

  /**
   * Toggle type filter
   */
  toggleTypeFilter(type: string): void {
    const index = this.typeFilters.indexOf(type);
    if (index > -1) {
      this.typeFilters.splice(index, 1);
    } else {
      this.typeFilters.push(type);
    }
    this.applyFilters();
  }

  /**
   * Toggle level filter
   */
  toggleLevelFilter(level: string): void {
    const index = this.levelFilters.indexOf(level);
    if (index > -1) {
      this.levelFilters.splice(index, 1);
    } else {
      this.levelFilters.push(level);
    }
    this.applyFilters();
  }

  /**
   * Toggle discipline filter
   */
  toggleDisciplineFilter(discipline: string): void {
    const index = this.disciplineFilters.indexOf(discipline);
    if (index > -1) {
      this.disciplineFilters.splice(index, 1);
    } else {
      this.disciplineFilters.push(discipline);
    }
    this.applyFilters();
  }

  /**
   * Clear all filters
   */
  clearFilters(): void {
    this.typeFilters = [];
    this.levelFilters = [];
    this.disciplineFilters = [];
    this.applyFilters();
  }

  /**
   * Apply filters (re-trigger search if active)
   */
  private applyFilters(): void {
    if (this.searchQuery && this.searchQuery.length >= 2) {
      this.searchSubject.next(this.searchQuery);
    }
    this.cdr.markForCheck();
  }

  // ==================== KEYBOARD NAVIGATION ====================

  /**
   * Handle keyboard events
   */
  onKeyDown(event: KeyboardEvent, node: TreeNodeState): void {
    switch (event.key) {
      case 'ArrowRight':
        if (node.has_children && !node.expanded) {
          this.toggleExpand(node);
        }
        event.preventDefault();
        break;

      case 'ArrowLeft':
        if (node.expanded) {
          this.toggleExpand(node);
        } else if (node.parent) {
          this.selectNode(node.parent);
        }
        event.preventDefault();
        break;

      case 'ArrowDown':
        this.selectNextNode(node);
        event.preventDefault();
        break;

      case 'ArrowUp':
        this.selectPreviousNode(node);
        event.preventDefault();
        break;

      case 'Enter':
      case ' ':
        this.selectNode(node);
        event.preventDefault();
        break;
    }
  }

  /**
   * Select next visible node
   */
  private selectNextNode(currentNode: TreeNodeState): void {
    const currentIndex = this.flattenedNodes.indexOf(currentNode);
    if (currentIndex < this.flattenedNodes.length - 1) {
      this.selectNode(this.flattenedNodes[currentIndex + 1]);
    }
  }

  /**
   * Select previous visible node
   */
  private selectPreviousNode(currentNode: TreeNodeState): void {
    const currentIndex = this.flattenedNodes.indexOf(currentNode);
    if (currentIndex > 0) {
      this.selectNode(this.flattenedNodes[currentIndex - 1]);
    }
  }

  // ==================== UTILITIES ====================

  /**
   * Get icon class for node type
   */
  getNodeIcon(node: TreeNodeState): string {
    if (node.icon) return node.icon;

    switch (node.type) {
      case 'root':
        return 'icon-projects';
      case 'site':
        return 'icon-location';
      case 'building':
        return 'icon-building';
      case 'storey':
        return 'icon-layers';
      case 'space':
        return 'icon-box';
      case 'type_group':
        return 'icon-folder';
      case 'discipline_group':
        return 'icon-folder-open';
      default:
        return 'icon-cube';
    }
  }

  /**
   * Track by function for *ngFor performance
   */
  trackByNodeId(_index: number, node: TreeNodeState): string {
    return node.id;
  }
}
