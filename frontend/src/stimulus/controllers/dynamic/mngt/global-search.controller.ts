import { Controller } from '@hotwired/stimulus';
import { visit } from '@hotwired/turbo';

const RECENT_ITEMS_KEY = 'openproject:recent-work-packages';
const MAX_RECENT = 5;
const DEBOUNCE_MS = 300;
const MIN_QUERY_LENGTH = 2;

interface WorkPackageResult {
  id: number;
  subject: string;
  project: string;
  type: string;
  _links?: { self?: { href: string } };
}

interface RecentItem {
  id: number;
  subject: string;
  project: string;
  type: string;
  href: string;
}

export default class extends Controller {
  static targets = ['input', 'results'];
  static values = {
    projectScope: { type: String, default: '' },
  };

  declare inputTarget: HTMLInputElement;
  declare resultsTarget: HTMLElement;
  declare hasResultsTarget: boolean;
  declare projectScopeValue: string;

  private debounceTimer: ReturnType<typeof setTimeout> | null = null;
  private activeIndex = -1;
  private currentItems: Array<{ href: string; label: string; secondary: string }> = [];

  connect(): void {
    this.inputTarget.addEventListener('input', this.onInput);
    this.inputTarget.addEventListener('keydown', this.onKeydown);
    this.inputTarget.addEventListener('focus', this.onFocus);
    document.addEventListener('click', this.onDocumentClick);
  }

  disconnect(): void {
    this.inputTarget.removeEventListener('input', this.onInput);
    this.inputTarget.removeEventListener('keydown', this.onKeydown);
    this.inputTarget.removeEventListener('focus', this.onFocus);
    document.removeEventListener('click', this.onDocumentClick);
    this.clearDebounce();
  }

  private readonly onInput = (): void => {
    this.clearDebounce();
    const q = this.inputTarget.value.trim();
    if (q.length < MIN_QUERY_LENGTH) {
      if (q.length === 0) this.showRecent();
      else this.closeResults();
      return;
    }
    this.debounceTimer = setTimeout(() => void this.search(q), DEBOUNCE_MS);
  };

  private readonly onFocus = (): void => {
    if (this.inputTarget.value.trim().length === 0) this.showRecent();
  };

  private readonly onKeydown = (event: KeyboardEvent): void => {
    if (!this.hasResultsTarget || this.resultsTarget.hidden) return;

    if (event.key === 'ArrowDown') {
      event.preventDefault();
      this.moveActive(1);
    } else if (event.key === 'ArrowUp') {
      event.preventDefault();
      this.moveActive(-1);
    } else if (event.key === 'Enter' && this.activeIndex >= 0) {
      event.preventDefault();
      const item = this.currentItems[this.activeIndex];
      if (item) visit = item.href;
    } else if (event.key === 'Escape') {
      this.closeResults();
      this.inputTarget.blur();
    }
  };

  private readonly onDocumentClick = (event: Event): void => {
    if (!this.element.contains(event.target as Node)) this.closeResults();
  };

  private moveActive(delta: number): void {
    const count = this.currentItems.length;
    if (count === 0) return;
    this.activeIndex = (this.activeIndex + delta + count) % count;
    this.renderActive();
  }

  private renderActive(): void {
    if (!this.hasResultsTarget) return;
    const items = this.resultsTarget.querySelectorAll('li');
    items.forEach((li, i) => li.setAttribute('aria-selected', String(i === this.activeIndex)));
  }

  private async search(q: string): Promise<void> {
    const isId = /^#?\d+$/.test(q.trim());
    const term = q.replace(/^#/, '').trim();
    if (!term) return;

    // Use subjectOrId filter which matches the Angular typeahead behaviour
    const filter = isId
      ? JSON.stringify([['id', '=', [term]]])
      : JSON.stringify([['subjectOrId', '~', [term]]]);

    const projectFilter = this.projectScopeValue
      ? `&filters=${encodeURIComponent(JSON.stringify([['project', '=', [this.projectScopeValue]], ['subjectOrId', '~', [term]]]))}`
      : `&filters=${encodeURIComponent(filter)}`;

    const url = `/api/v3/work_packages?pageSize=10&sortBy=${encodeURIComponent(JSON.stringify([['updatedAt', 'desc']]))}${projectFilter}`;

    try {
      const res = await fetch(url, { headers: { Accept: 'application/json' }, credentials: 'same-origin' });
      if (!res.ok) return;
      const data = await res.json() as { _embedded?: { elements?: WorkPackageResult[] } };
      const elements = data._embedded?.elements ?? [];
      this.showResults(elements.map((wp) => ({
        href: `/work_packages/${wp.id}`,
        label: `#${wp.id} ${wp.subject}`,
        secondary: wp.project ?? '',
      })));
    } catch {
      // Silently ignore
    }
  }

  private showRecent(): void {
    const recent = this.loadRecent();
    if (recent.length === 0) { this.closeResults(); return; }
    this.showResults(recent.map((r) => ({
      href: r.href,
      label: `#${r.id} ${r.subject}`,
      secondary: r.project ?? '',
    })));
  }

  private showResults(items: Array<{ href: string; label: string; secondary: string }>): void {
    if (!this.hasResultsTarget) return;
    this.currentItems = items;
    this.activeIndex = -1;

    if (items.length === 0) { this.closeResults(); return; }

    this.resultsTarget.innerHTML = items.map((item, i) =>
      `<li role="option" aria-selected="false" data-index="${i}">
        <a href="${this.escapeAttr(item.href)}" data-turbo="true">
          <span class="top-menu-search--result-label">${this.escapeHtml(item.label)}</span>
          ${item.secondary ? `<span class="top-menu-search--result-secondary">${this.escapeHtml(item.secondary)}</span>` : ''}
        </a>
      </li>`
    ).join('');

    this.resultsTarget.querySelectorAll('li').forEach((li) => {
      li.addEventListener('mousedown', (e) => {
        e.preventDefault();
        const idx = Number((e.currentTarget as HTMLElement).dataset.index);
        const item = this.currentItems[idx];
        if (item) this.navigateTo(item.href);
      });
    });

    this.resultsTarget.hidden = false;
  }

  private closeResults(): void {
    if (!this.hasResultsTarget) return;
    this.resultsTarget.hidden = true;
    this.resultsTarget.innerHTML = '';
    this.currentItems = [];
    this.activeIndex = -1;
  }

  private navigateTo(href: string): void {
    const q = this.inputTarget.value.trim();
    if (q) this.addToRecent(href, q);
    visit = href;
  }

  private clearDebounce(): void {
    if (this.debounceTimer !== null) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = null;
    }
  }

  // ── Recent items ──────────────────────────────────────────────

  private loadRecent(): RecentItem[] {
    try {
      return JSON.parse(localStorage.getItem(RECENT_ITEMS_KEY) ?? '[]') as RecentItem[];
    } catch { return []; }
  }

  private addToRecent(href: string, _q: string): void {
    // Work package href looks like /work_packages/123
    const match = href.match(/\/work_packages\/(\d+)/);
    if (!match) return;
    const id = Number(match[1]);
    const recent = this.loadRecent().filter((r) => r.id !== id);
    // We don't have full metadata here; just store the href and id
    // Real subject/project will appear on next API result
    const entry: RecentItem = { id, subject: `#${id}`, project: '', type: '', href };
    recent.unshift(entry);
    try {
      localStorage.setItem(RECENT_ITEMS_KEY, JSON.stringify(recent.slice(0, MAX_RECENT)));
    } catch { /* ignore quota errors */ }
  }

  // ── Utilities ─────────────────────────────────────────────────

  private escapeHtml(str: string): string {
    return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  private escapeAttr(str: string): string {
    return str.replace(/"/g, '&quot;');
  }
}
