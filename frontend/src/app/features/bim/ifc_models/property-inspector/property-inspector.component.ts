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
  OnChanges,
  SimpleChanges,
  ChangeDetectorRef,
  ChangeDetectionStrategy,
} from '@angular/core';
import {
  V97ApiService,
  ElementProperties,
  PropertyHistoryEntry,
  RelatedElements,
} from '../services/v9-7-api.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';

/**
 * Property Inspector Component (V9.7 UX/UI Polish)
 *
 * Enhanced property viewer for IFC elements with:
 * - 5 property categories (basic, geometry, materials, status, custom)
 * - Inline editing for custom properties
 * - Property history timeline
 * - Related elements navigation
 * - Collapsible sections
 * - Copy to clipboard
 *
 * Usage:
 *   <op-property-inspector
 *     [ifcModelId]="123"
 *     [elementGuid]="'abc-123-xyz'"
 *     [canEdit]="true"
 *     (propertyUpdated)="onPropertyUpdated($event)">
 *   </op-property-inspector>
 */

@Component({
  selector: 'op-property-inspector',
  templateUrl: './property-inspector.component.html',
  styleUrls: ['./property-inspector.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: false,
})
export class PropertyInspectorComponent implements OnChanges {
  @Input() ifcModelId!: number;

  @Input() elementGuid: string | null = null;

  @Input() canEdit = false;

  @Output() propertyUpdated = new EventEmitter<{ property: string; value: any }>();

  @Output() relatedElementSelected = new EventEmitter<string>();

  // Property data
  properties: ElementProperties | null = null;

  history: PropertyHistoryEntry[] = [];

  relatedElements: RelatedElements | null = null;

  loading = true;

  error: string | null = null;

  // UI state
  expandedSections: Set<string> = new Set(['basic', 'geometry', 'materials', 'status', 'custom']);

  activeTab: 'properties' | 'history' | 'related' = 'properties';

  // Editing state
  editingProperty: string | null = null;

  editValue: any = null;

  saving = false;

  // i18n text
  text = {
    no_element_selected: this.I18n.t('js.bim.property_inspector.no_element_selected'),
    loading: this.I18n.t('js.bim.property_inspector.loading'),
    tab_properties: this.I18n.t('js.bim.property_inspector.tab_properties'),
    tab_history: this.I18n.t('js.bim.property_inspector.tab_history'),
    tab_related: this.I18n.t('js.bim.property_inspector.tab_related'),
    section_basic: this.I18n.t('js.bim.property_inspector.section_basic'),
    section_geometry: this.I18n.t('js.bim.property_inspector.section_geometry'),
    section_materials: this.I18n.t('js.bim.property_inspector.section_materials'),
    section_status: this.I18n.t('js.bim.property_inspector.section_status'),
    section_custom: this.I18n.t('js.bim.property_inspector.section_custom'),
    edit: this.I18n.t('js.bim.property_inspector.edit'),
    save: this.I18n.t('js.bim.property_inspector.save'),
    cancel: this.I18n.t('js.bim.property_inspector.cancel'),
    copy: this.I18n.t('js.bim.property_inspector.copy'),
    copied: this.I18n.t('js.bim.property_inspector.copied'),
    no_history: this.I18n.t('js.bim.property_inspector.no_history'),
    parent_element: this.I18n.t('js.bim.property_inspector.parent_element'),
    child_elements: this.I18n.t('js.bim.property_inspector.child_elements'),
    no_related: this.I18n.t('js.bim.property_inspector.no_related'),
  };

  constructor(
    private apiService: V97ApiService,
    private I18n: I18nService,
    private cdr: ChangeDetectorRef,
  ) {}

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['elementGuid'] || changes['ifcModelId']) {
      this.loadProperties();
    }
  }

  // ==================== DATA LOADING ====================

  /**
   * Load element properties from API
   */
  private loadProperties(): void {
    if (!this.elementGuid || !this.ifcModelId) {
      this.properties = null;
      this.loading = false;
      return;
    }

    this.loading = true;
    this.error = null;
    this.cdr.markForCheck();

    this.apiService.getElementProperties(this.ifcModelId, this.elementGuid).subscribe({
      next: (properties) => {
        this.properties = properties;
        this.loading = false;
        this.cdr.markForCheck();

        // Load history and related elements in background
        if (this.activeTab === 'history') {
          this.loadHistory();
        } else if (this.activeTab === 'related') {
          this.loadRelatedElements();
        }
      },
      error: (err) => {
        this.error = err.message || 'Failed to load properties';
        this.loading = false;
        this.cdr.markForCheck();
      },
    });
  }

  /**
   * Load property history from API
   */
  private loadHistory(): void {
    if (!this.elementGuid || !this.ifcModelId) {
      return;
    }

    this.apiService.getPropertyHistory(this.ifcModelId, this.elementGuid).subscribe({
      next: (history) => {
        this.history = history;
        this.cdr.markForCheck();
      },
      error: (err) => {
        console.error('Failed to load history:', err);
      },
    });
  }

  /**
   * Load related elements from API
   */
  private loadRelatedElements(): void {
    if (!this.elementGuid || !this.ifcModelId) {
      return;
    }

    this.apiService.getRelatedElements(this.ifcModelId, this.elementGuid).subscribe({
      next: (related) => {
        this.relatedElements = related;
        this.cdr.markForCheck();
      },
      error: (err) => {
        console.error('Failed to load related elements:', err);
      },
    });
  }

  // ==================== TAB SWITCHING ====================

  /**
   * Switch active tab
   */
  switchTab(tab: 'properties' | 'history' | 'related'): void {
    this.activeTab = tab;

    // Load data on demand
    if (tab === 'history' && this.history.length === 0) {
      this.loadHistory();
    } else if (tab === 'related' && !this.relatedElements) {
      this.loadRelatedElements();
    }

    this.cdr.markForCheck();
  }

  // ==================== SECTION TOGGLE ====================

  /**
   * Toggle section expansion
   */
  toggleSection(section: string): void {
    if (this.expandedSections.has(section)) {
      this.expandedSections.delete(section);
    } else {
      this.expandedSections.add(section);
    }
    this.cdr.markForCheck();
  }

  /**
   * Check if section is expanded
   */
  isSectionExpanded(section: string): boolean {
    return this.expandedSections.has(section);
  }

  // ==================== PROPERTY EDITING ====================

  /**
   * Start editing a custom property
   */
  startEdit(propertyName: string, currentValue: any): void {
    if (!this.canEdit) {
      return;
    }

    this.editingProperty = propertyName;
    this.editValue = currentValue;
    this.cdr.markForCheck();
  }

  /**
   * Cancel editing
   */
  cancelEdit(): void {
    this.editingProperty = null;
    this.editValue = null;
    this.cdr.markForCheck();
  }

  /**
   * Save edited property
   */
  saveEdit(propertyName: string): void {
    if (!this.canEdit || !this.elementGuid || !this.ifcModelId) {
      return;
    }

    this.saving = true;
    this.cdr.markForCheck();

    const customProperties = { [propertyName]: this.editValue };

    this.apiService
      .updateElementProperties(this.ifcModelId, this.elementGuid, customProperties)
      .subscribe({
        next: (updatedProperties) => {
          this.properties = updatedProperties;
          this.editingProperty = null;
          this.editValue = null;
          this.saving = false;
          this.propertyUpdated.emit({ property: propertyName, value: this.editValue });
          this.cdr.markForCheck();
        },
        error: (err) => {
          console.error('Failed to update property:', err);
          this.saving = false;
          this.cdr.markForCheck();
        },
      });
  }

  // ==================== COPY TO CLIPBOARD ====================

  /**
   * Copy property value to clipboard
   */
  copyToClipboard(value: any): void {
    const text = typeof value === 'object' ? JSON.stringify(value, null, 2) : String(value);

    if (navigator.clipboard) {
      navigator.clipboard.writeText(text).then(
        () => {
          // Show temporary "Copied!" indicator
          // Could use a toast notification here
          console.log('Copied to clipboard');
        },
        (err) => {
          console.error('Failed to copy:', err);
        },
      );
    }
  }

  // ==================== RELATED ELEMENTS ====================

  /**
   * Navigate to related element
   */
  selectRelatedElement(guid: string): void {
    this.relatedElementSelected.emit(guid);
  }

  // ==================== UTILITIES ====================

  /**
   * Format property value for display
   */
  formatValue(value: any): string {
    if (value === null || value === undefined) {
      return 'N/A';
    }

    if (typeof value === 'number') {
      return value.toLocaleString(undefined, { maximumFractionDigits: 2 });
    }

    if (typeof value === 'boolean') {
      return value ? 'Yes' : 'No';
    }

    if (typeof value === 'object') {
      return JSON.stringify(value);
    }

    return String(value);
  }

  /**
   * Get property entries as array for iteration
   */
  getPropertyEntries(obj: Record<string, any> | undefined): Array<[string, any]> {
    if (!obj) {
      return [];
    }
    return Object.entries(obj).filter(([_, value]) => value !== null && value !== undefined);
  }

  /**
   * Format timestamp for display
   */
  formatTimestamp(timestamp: string): string {
    return new Date(timestamp).toLocaleString();
  }

  /**
   * Get action icon for history entry
   */
  getHistoryActionIcon(action: string): string {
    switch (action) {
      case 'create':
        return 'icon-add';
      case 'update':
        return 'icon-edit';
      case 'delete':
        return 'icon-delete';
      default:
        return 'icon-info1';
    }
  }

  /**
   * Track by function for *ngFor performance
   */
  trackByIndex(index: number): number {
    return index;
  }
}
