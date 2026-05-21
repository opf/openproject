import { Controller } from '@hotwired/stimulus';

const DISMISS_KEY = 'mngt_pwa_dismissed_at';

interface BeforeInstallPromptEvent extends Event {
  prompt(): Promise<void>;
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>;
}

export default class PwaInstallController extends Controller {
  static targets = ['overlay', 'sheet', 'installBtn', 'iosHint'];
  static values = { dismissDays: { type: Number, default: 3 } };

  declare overlayTarget: HTMLElement;
  declare sheetTarget: HTMLElement;
  declare installBtnTarget: HTMLElement;
  declare iosHintTarget: HTMLElement;
  declare dismissDaysValue: number;

  private deferredPrompt: BeforeInstallPromptEvent | null = null;
  private boundPromptHandler: (e: Event) => void;

  connect() {
    if (!this.shouldShow()) return;

    // Event may have fired before this controller connected — check global capture
    const early = (window as Window & { __pwaPrompt?: Event }).__pwaPrompt;
    if (early) {
      this.deferredPrompt = early as BeforeInstallPromptEvent;
      this.show();
      return;
    }

    this.boundPromptHandler = (e: Event) => {
      e.preventDefault();
      this.deferredPrompt = e as BeforeInstallPromptEvent;
      this.show();
    };

    window.addEventListener('beforeinstallprompt', this.boundPromptHandler);

    // iOS doesn't fire beforeinstallprompt — show manual instructions instead
    if (this.isIos() && !this.isStandalone()) {
      this.iosHintTarget.hidden = false;
      this.installBtnTarget.hidden = true;
      this.show();
    }
  }

  disconnect() {
    if (this.boundPromptHandler) {
      window.removeEventListener('beforeinstallprompt', this.boundPromptHandler);
    }
  }

  install() {
    if (!this.deferredPrompt) return;

    void this.deferredPrompt.prompt();
    void this.deferredPrompt.userChoice.then(({ outcome }) => {
      if (outcome === 'accepted') this.hide();
      this.deferredPrompt = null;
    });
  }

  dismiss() {
    localStorage.setItem(DISMISS_KEY, String(Date.now()));
    this.hide();
  }

  private show() {
    this.overlayTarget.classList.add('mngt-pwa-overlay--visible');
    this.sheetTarget.classList.add('mngt-pwa-sheet--visible');
    document.body.style.overflow = 'hidden';
  }

  private hide() {
    this.overlayTarget.classList.remove('mngt-pwa-overlay--visible');
    this.sheetTarget.classList.remove('mngt-pwa-sheet--visible');
    document.body.style.overflow = '';
  }

  private shouldShow(): boolean {
    if (this.isStandalone()) return false;
    const raw = localStorage.getItem(DISMISS_KEY);
    if (!raw) return true;
    const daysSince = (Date.now() - Number(raw)) / 86_400_000;
    return daysSince >= this.dismissDaysValue;
  }

  private isStandalone(): boolean {
    return (
      window.matchMedia('(display-mode: standalone)').matches ||
      (navigator as Navigator & { standalone?: boolean }).standalone === true
    );
  }

  private isIos(): boolean {
    return /iphone|ipad|ipod/i.test(navigator.userAgent);
  }
}
