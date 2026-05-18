import { Controller } from '@hotwired/stimulus';

export default class MngtThemeToggle extends Controller {
  static values = { theme: String };

  declare themeValue: string;

  toggle(): void {
    const next = this.themeValue === 'dark' ? 'light' : 'dark';
    const csrfMeta = document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement | null;
    const csrfToken = csrfMeta?.content ?? '';

    fetch('/mngt/theme', {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
      },
      body: JSON.stringify({ theme: next }),
    })
      .then((res) => {
        if (!res.ok) return;
        this.themeValue = next;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        (window as any).OpenProject.theme.applyThemeToBody(next, false);
        const btn = this.element.querySelector('.mngt-theme-toggle-btn') as HTMLButtonElement | null;
        if (btn) {
          btn.setAttribute('aria-label', next === 'dark' ? 'Mudar para modo claro' : 'Mudar para modo escuro');
        }
      })
      .catch(() => { /* silent */ });
  }
}
