import { Controller } from '@hotwired/stimulus';
import { type StreamChat, type Channel, type Event as StreamEvent } from 'stream-chat';
import { getStreamClient } from './stream-client';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyRecord = Record<string, any>;

interface StreamUser {
  id:        string;
  name:      string;
  avatarUrl?: string;
}

const DM_PALETTE = ['#7c3aed', '#2563eb', '#059669', '#dc2626', '#d97706', '#0891b2', '#be185d', '#65a30d'];

function avatarColor(name: string): string {
  let hash = 0;
  for (let i = 0; i < name.length; i++) hash = name.charCodeAt(i) + ((hash << 5) - hash);
  return DM_PALETTE[Math.abs(hash) % DM_PALETTE.length];
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyChannel = Channel;

export default class MngtChatRoomsController extends Controller<HTMLElement> {
  static targets = ['channelsList', 'dmsList'];
  static values  = {
    usersUrl:      String,
    dmUrl:         String,
    channelsUrl:   String,
    currentUserId: String,
    notify:        Boolean,
    isAdmin:       Boolean,
    companySlug:   String,
    canSeeAll:     Boolean,
    companiesMap:  String,
  };

  declare channelsListTarget: HTMLElement;
  declare dmsListTarget:      HTMLElement;

  declare usersUrlValue:      string;
  declare dmUrlValue:         string;
  declare channelsUrlValue:   string;
  declare currentUserIdValue: string;
  declare notifyValue:        boolean;
  declare isAdminValue:       boolean;
  declare companySlugValue:   string;
  declare canSeeAllValue:     boolean;
  declare companiesMapValue:  string;

  private client:        StreamChat | null = null;
  private modalAllUsers: StreamUser[] = [];
  private audioCtx:      AudioContext | null = null;
  private presenceMap:   Map<string, boolean> = new Map();

  private readonly onNotificationMessage = (_event: StreamEvent): void => {
    void this.refreshChannels();
    if (this.notifyValue) {
      const ch      = (_event as unknown as { channel?: { name?: string; id?: string } }).channel;
      const muted   = !!ch?.id && localStorage.getItem(`mngt_muted_${ch.id}`) === 'true';
      if (!muted) {
        this.playSound();
        void this.showBrowserNotification(ch?.name || ch?.id || '');
      }
    }
  };

  private readonly onAddedToChannel = (): void => { void this.refreshChannels(); };

  private readonly onChannelRead = (): void => { void this.refreshChannels(); };

  private readonly onOpenNewDm      = (): void => { this.openNewDmModal(); };
  private readonly onOpenNewChannel = (): void => { if (this.isAdminValue) this.openNewChannelModal(); };

  private readonly onPresenceChanged = (event: StreamEvent): void => {
    const user = event.user;
    if (!user?.id) return;
    const online = (user.online as boolean) ?? false;
    this.presenceMap.set(user.id, online);
    this.dmsListTarget.querySelectorAll<HTMLElement>(`[data-presence-id="${user.id}"]`).forEach((dot) => {
      dot.hidden = !online;
    });
  };

  private readonly unlockAudio = (): void => {
    if (!this.audioCtx) this.audioCtx = new AudioContext();
    if (this.audioCtx.state === 'suspended') void this.audioCtx.resume();
  };

  private readonly escHandler = (e: KeyboardEvent): void => {
    if (e.key === 'Escape') this.closeDmModal();
  };

  connect(): void {
    void this.waitAndLoad();
    if (this.notifyValue) void this.requestNotificationPermission();
    document.addEventListener('mngt:channel-read',    this.onChannelRead);
    document.addEventListener('mngt:open-new-dm',     this.onOpenNewDm);
    document.addEventListener('mngt:open-new-channel', this.onOpenNewChannel);
    document.addEventListener('click', this.unlockAudio, { once: true });
  }

  disconnect(): void {
    this.client?.off('notification.message_new', this.onNotificationMessage);
    this.client?.off('notification.added_to_channel', this.onAddedToChannel);
    this.client?.off('user.presence.changed', this.onPresenceChanged);
    document.removeEventListener('mngt:channel-read',    this.onChannelRead);
    document.removeEventListener('mngt:open-new-dm',     this.onOpenNewDm);
    document.removeEventListener('mngt:open-new-channel', this.onOpenNewChannel);
    this.closeDmModal();
  }

  // Action: open a channel or DM from the sidebar list
  openChannel(event: Event): void {
    const btn         = event.currentTarget as HTMLElement;
    const channelId   = btn.dataset['channelId']   ?? '';
    const channelType = btn.dataset['channelType']  ?? 'team';
    const displayName = btn.dataset['displayName'];
    document.dispatchEvent(new CustomEvent('mngt:chat-navigate', {
      detail: { channelId, channelType, ...(displayName ? { displayName } : {}) },
    }));
  }

  // Action: open the new-conversation modal
  openNewDmModal(): void {
    this.closeDmModal();

    const modal = document.createElement('div');
    modal.id    = 'mngt-dm-modal';
    modal.className = 'mngt-dm-modal';
    modal.innerHTML = `
      <div class="mngt-dm-modal-backdrop"></div>
      <div class="mngt-dm-modal-body" role="dialog" aria-modal="true" aria-label="Nova mensagem">
        <div class="mngt-dm-modal-header">
          <span>Nova mensagem</span>
          <button class="mngt-dm-modal-close" aria-label="Fechar">×</button>
        </div>
        <input class="mngt-dm-modal-search" type="text" placeholder="Buscar usuário..." autocomplete="off" />
        <div class="mngt-dm-modal-group-name" hidden>
          <input class="mngt-dm-modal-group-input" type="text" placeholder="Nome do grupo (opcional)" autocomplete="off" maxlength="80" />
        </div>
        <div class="mngt-dm-modal-count" hidden></div>
        <div class="mngt-dm-modal-users" id="mngt-dm-modal-users">
          <span class="mngt-dm-modal-empty">Carregando...</span>
        </div>
        <div class="mngt-dm-modal-footer">
          <button class="mngt-dm-modal-btn" disabled>Criar conversa</button>
        </div>
      </div>`;

    document.body.appendChild(modal);
    document.addEventListener('keydown', this.escHandler);

    modal.querySelector('.mngt-dm-modal-backdrop')!.addEventListener('click', () => this.closeDmModal());
    modal.querySelector('.mngt-dm-modal-close')!.addEventListener('click', () => this.closeDmModal());
    modal.querySelector('.mngt-dm-modal-search')!.addEventListener('input', (e) => {
      this.filterModalUsers((e.target as HTMLInputElement).value);
    });
    modal.querySelector('.mngt-dm-modal-btn')!.addEventListener('click', () => { void this.submitNewDm(); });

    modal.querySelector<HTMLInputElement>('.mngt-dm-modal-search')?.focus();
    void this.loadModalUsers();
  }

  closeDmModal(): void {
    document.removeEventListener('keydown', this.escHandler);
    document.getElementById('mngt-dm-modal')?.remove();
    this.modalAllUsers = [];
  }

  // ── private ────────────────────────────────────────────────────

  private async waitAndLoad(): Promise<void> {
    try {
      this.renderLoading();
      this.client = await getStreamClient();

      await this.ensureGeralChannel();
      await this.refreshChannels();

      this.client.on('notification.message_new',      this.onNotificationMessage);
      this.client.on('notification.added_to_channel', this.onAddedToChannel);
      this.client.on('user.presence.changed',         this.onPresenceChanged);
    } catch {
      this.renderChannelsEmpty();
      this.renderDmsEmpty();
    }
  }

  // Create the default "Geral" team channel for the current user's company via SDK.
  // Stream channel creation requires a WebSocket handshake (SDK), not plain HTTP.
  // The backend is notified afterward to add the right users as members.
  private async ensureGeralChannel(): Promise<void> {
    if (!this.client) return;
    try {
      const slug      = this.companySlugValue || 'unknown';
      const channelId = `${slug}--geral`;
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const ch = this.client.channel('team', channelId, { name: 'Geral' } as any);
      await ch.watch();
      void fetch(this.channelsUrlValue, {
        method:      'POST',
        credentials: 'same-origin',
        headers: {
          'Content-Type': 'application/json',
          'Accept':       'application/json',
          'X-CSRF-Token': this.csrfToken(),
        },
        body: JSON.stringify({ channelId, name: 'Geral' }),
      });
    } catch {
      // Non-fatal — channel may already exist or creation may fail silently.
    }
  }

  private get companiesMap(): Record<string, string> {
    try {
      return JSON.parse(this.companiesMapValue || '{}') as Record<string, string>;
    } catch {
      return {};
    }
  }

  private companyNameFromChannelId(channelId: string): string {
    const slug = channelId.split('--')[0] ?? '';
    return this.companiesMap[slug] ?? slug;
  }

  private async refreshChannels(): Promise<void> {
    if (!this.client) return;

    const sort = [{ last_message_at: -1 }, { created_at: -1 }] as const;
    const opts  = { limit: 30, state: true, watch: false };

    // Team channels are public — query by type so new users see them without being members.
    // DMs are private — filter by current user's membership.
    const [team, dms] = await Promise.all([
      this.client.queryChannels({ type: 'team' }, sort, opts),
      this.client.queryChannels(
        { type: 'messaging', members: { $in: [this.currentUserIdValue] } },
        sort,
        opts,
      ),
    ]);

    this.renderTeamChannels(team);
    this.renderDms(dms);
    void this.refreshPresence(dms);
  }

  private renderLoading(): void {
    this.channelsListTarget.innerHTML =
      '<span class="mngt-sidebar-item mngt-sidebar-item--empty">Carregando...</span>';
    this.dmsListTarget.innerHTML =
      '<span class="mngt-sidebar-item mngt-sidebar-item--empty">Carregando...</span>';
  }

  private renderTeamChannels(channels: AnyChannel[]): void {
    if (channels.length === 0) { this.renderChannelsEmpty(); return; }

    const channelBtn = (ch: AnyChannel): string => {
      const data   = ch.data as Record<string, unknown> | undefined;
      const name   = (data?.['name'] as string | undefined) ?? ch.id ?? '';
      const unread = ch.countUnread();
      return `
        <button class="mngt-sidebar-item"
                data-action="click->mngt--chat-rooms#openChannel"
                data-channel-id="${ch.id}"
                data-channel-type="${ch.type}"
                title="${this.esc(name)}">
          <span class="mngt-sidebar-channel-hash">#</span>
          <span class="mngt-sidebar-label">${this.esc(name)}</span>
          ${unread > 0 ? `<span class="mngt-sidebar-badge">${unread > 99 ? '99+' : unread}</span>` : ''}
        </button>`;
    };

    if (this.canSeeAllValue) {
      // CSC: group channels by company — skip channels with unrecognized prefixes (legacy)
      const knownSlugs = new Set(Object.keys(this.companiesMap));
      const validChannels = channels.filter((ch) => {
        const slug = (ch.id ?? '').split('--')[0] ?? '';
        return knownSlugs.has(slug);
      });

      const groups = new Map<string, AnyChannel[]>();
      for (const ch of validChannels) {
        const company = this.companyNameFromChannelId(ch.id ?? '');
        if (!groups.has(company)) groups.set(company, []);
        groups.get(company)!.push(ch);
      }

      let html = '';
      groups.forEach((chs, companyName) => {
        html += `<div class="mngt-sidebar-company-group">
          <div class="mngt-sidebar-company-label">${this.esc(companyName)}</div>
          ${chs.map(channelBtn).join('')}
        </div>`;
      });
      this.channelsListTarget.innerHTML = html + (this.isAdminValue ? this.newChannelButton() : '');
    } else {
      // Regular user: flat list
      this.channelsListTarget.innerHTML =
        channels.map(channelBtn).join('') + (this.isAdminValue ? this.newChannelButton() : '');
    }
  }

  private newChannelButton(): string {
    return `<button class="mngt-sidebar-new-dm" data-action="click->mngt--chat-rooms#openNewChannelModal">
      <span class="mngt-sidebar-new-dm-plus">+</span> Novo canal
    </button>`;
  }

  // Action: open the new-channel modal (admin only)
  openNewChannelModal(): void {
    document.getElementById('mngt-channel-modal')?.remove();

    const modal = document.createElement('div');
    modal.id    = 'mngt-channel-modal';
    modal.className = 'mngt-dm-modal';
    modal.innerHTML = `
      <div class="mngt-dm-modal-backdrop"></div>
      <div class="mngt-dm-modal-body" role="dialog" aria-modal="true" aria-label="Novo canal">
        <div class="mngt-dm-modal-header">
          <span>Novo canal</span>
          <button class="mngt-dm-modal-close" aria-label="Fechar">×</button>
        </div>
        <input class="mngt-dm-modal-search" type="text" placeholder="Nome do canal..." autocomplete="off" maxlength="80" id="mngt-channel-name-input" />
        <div class="mngt-dm-modal-footer">
          <button class="mngt-dm-modal-btn" disabled>Criar canal</button>
        </div>
      </div>`;

    document.body.appendChild(modal);
    document.addEventListener('keydown', this.escChannelHandler);

    modal.querySelector('.mngt-dm-modal-backdrop')!.addEventListener('click', () => this.closeChannelModal());
    modal.querySelector('.mngt-dm-modal-close')!.addEventListener('click',    () => this.closeChannelModal());
    modal.querySelector('.mngt-dm-modal-btn')!.addEventListener('click', () => { void this.submitNewChannel(); });

    const input = modal.querySelector<HTMLInputElement>('#mngt-channel-name-input')!;
    input.addEventListener('input', () => {
      const btn = modal.querySelector<HTMLButtonElement>('.mngt-dm-modal-btn')!;
      btn.disabled = input.value.trim().length === 0;
    });
    input.focus();
  }

  private readonly escChannelHandler = (e: KeyboardEvent): void => {
    if (e.key === 'Escape') this.closeChannelModal();
  };

  private closeChannelModal(): void {
    document.removeEventListener('keydown', this.escChannelHandler);
    document.getElementById('mngt-channel-modal')?.remove();
  }

  private async submitNewChannel(): Promise<void> {
    const modal = document.getElementById('mngt-channel-modal');
    if (!modal) return;

    const input = modal.querySelector<HTMLInputElement>('#mngt-channel-name-input')!;
    const name  = input.value.trim();
    if (!name || !this.client) return;

    const btn = modal.querySelector<HTMLButtonElement>('.mngt-dm-modal-btn')!;
    btn.disabled    = true;
    btn.textContent = '...';

    try {
      // Stream channel creation requires the JS SDK (WebSocket handshake).
      // Channel ID is prefixed with the company slug for multi-tenant isolation.
      const slug      = this.companySlugValue || 'unknown';
      const base      = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '') || 'canal';
      const channelId = `${slug}--${base}-${Math.random().toString(16).slice(2, 8)}`;

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const ch = this.client.channel('team', channelId, { name } as any);
      await ch.watch();

      // Backend adds all OpenProject users as members (idempotent, fire-and-forget).
      void fetch(this.channelsUrlValue, {
        method:      'POST',
        credentials: 'same-origin',
        headers: {
          'Content-Type': 'application/json',
          'Accept':       'application/json',
          'X-CSRF-Token': this.csrfToken(),
        },
        body: JSON.stringify({ channelId, name }),
      });

      this.closeChannelModal();
      document.dispatchEvent(new CustomEvent('mngt:chat-navigate', {
        detail: { channelId, channelType: 'team', displayName: name },
      }));
      void this.refreshChannels();
    } catch (err) {
      console.error('[mngt:chat] submitNewChannel error', err);
      btn.textContent = 'Erro';
      btn.disabled    = false;
    }
  }

  private newDmButton(): string {
    return `<button class="mngt-sidebar-new-dm" data-action="click->mngt--chat-rooms#openNewDmModal">
      <span class="mngt-sidebar-new-dm-plus">+</span> Nova mensagem
    </button>`;
  }

  private renderDms(channels: AnyChannel[]): void {
    if (channels.length === 0) { this.renderDmsEmpty(); return; }

    this.dmsListTarget.innerHTML = channels.map((ch) => {
      const data        = ch.data as Record<string, unknown> | undefined;
      const otherMembers = (Object.values(ch.state.members) as AnyRecord[])
        .filter((m) => m['user_id'] !== this.currentUserIdValue);
      const isGroup     = !/^op_\d+--op_\d+$/.test(ch.id ?? '');
      const name        = (data?.['name'] as string | undefined)
        ?? otherMembers.map((m) => (m['user']?.['name'] as string | undefined) ?? (m['user_id'] as string | undefined) ?? '?').join(', ')
        ?? ch.id
        ?? '';
      const unread      = ch.countUnread();

      const dmUserId   = !isGroup ? (otherMembers[0]?.['user_id'] as string | undefined) : undefined;
      const dmImage    = !isGroup ? (otherMembers[0]?.['user']?.['image'] as string | undefined) : undefined;
      const photoLayer = dmImage
        ? `<span style="position:absolute;inset:0;border-radius:inherit;background:url('${this.esc(dmImage)}') center/cover no-repeat"></span>`
        : '';
      const isOnline    = dmUserId ? (this.presenceMap.get(dmUserId) ?? false) : false;
      const presenceDot = dmUserId
        ? `<span class="mngt-sidebar-presence-dot" data-presence-id="${this.esc(dmUserId)}"${isOnline ? '' : ' hidden'}></span>`
        : '';
      const iconHtml = isGroup
        ? `<span class="mngt-sidebar-group-icon" aria-hidden="true"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="16" height="16"><path d="M7 14s-1 0-1-1 1-4 5-4 5 3 5 4-1 1-1 1H7Zm4-6a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z"/><path fill-rule="evenodd" d="M5.216 14A2.238 2.238 0 0 1 5 13c0-1.355.68-2.75 1.936-3.72A6.325 6.325 0 0 0 5 9c-4 0-5 3-5 4s1 1 1 1h4.216Z"/><path d="M4.5 8a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5Z"/></svg></span>`
        : `<span class="mngt-sidebar-dm-avatar-wrap"><span class="mngt-sidebar-avatar mngt-sidebar-avatar--sm" style="background:${avatarColor(name)}">${(name[0] ?? '?').toUpperCase()}${photoLayer}</span>${presenceDot}</span>`;

      return `
        <button class="mngt-sidebar-item"
                data-action="click->mngt--chat-rooms#openChannel"
                data-channel-id="${ch.id}"
                data-channel-type="${ch.type}"
                data-display-name="${this.esc(name)}"
                title="${this.esc(name)}">
          ${iconHtml}
          <span class="mngt-sidebar-label">${this.esc(name)}</span>
          ${unread > 0 ? `<span class="mngt-sidebar-badge">${unread > 99 ? '99+' : unread}</span>` : ''}
        </button>`;
    }).join('') + this.newDmButton();
  }

  private renderChannelsEmpty(): void {
    this.channelsListTarget.innerHTML =
      '<span class="mngt-sidebar-item mngt-sidebar-item--empty">Nenhum canal</span>' +
      (this.isAdminValue ? this.newChannelButton() : '');
  }

  private renderDmsEmpty(): void {
    this.dmsListTarget.innerHTML =
      '<span class="mngt-sidebar-item mngt-sidebar-item--empty">Nenhuma conversa</span>' +
      this.newDmButton();
  }

  // ── Modal internals ────────────────────────────────────────────

  private async loadModalUsers(): Promise<void> {
    const res = await fetch(this.usersUrlValue, {
      headers: { Accept: 'application/json' },
      credentials: 'same-origin',
    });
    if (!res.ok) return;
    this.modalAllUsers = await res.json() as StreamUser[];
    this.filterModalUsers('');
  }

  private filterModalUsers(query: string): void {
    const modal = document.getElementById('mngt-dm-modal');
    if (!modal) return;

    const q     = query.toLowerCase().trim();
    const users = q
      ? this.modalAllUsers.filter((u) => u.name.toLowerCase().includes(q))
      : this.modalAllUsers;
    const container = modal.querySelector('#mngt-dm-modal-users')!;

    if (users.length === 0) {
      container.innerHTML = '<span class="mngt-dm-modal-empty">Nenhum usuário encontrado</span>';
      return;
    }

    container.innerHTML = users.map((u) => {
      const initial    = (u.name[0] ?? '?').toUpperCase();
      const color      = avatarColor(u.name);
      const photoLayer = u.avatarUrl
        ? `<span style="position:absolute;inset:0;border-radius:inherit;background:url('${this.esc(u.avatarUrl)}') center/cover no-repeat"></span>`
        : '';
      return `
      <label class="mngt-dm-modal-user">
        <input type="checkbox" value="${u.id}" data-name="${this.esc(u.name)}" />
        <span class="mngt-sidebar-avatar mngt-sidebar-avatar--sm" style="background:${color}">${initial}${photoLayer}</span>
        <span>${this.esc(u.name)}</span>
      </label>`;
    }).join('');

    container.querySelectorAll<HTMLInputElement>('input[type="checkbox"]').forEach((cb) => {
      cb.addEventListener('change', () => this.updateModalSelection(modal));
    });
  }

  private updateModalSelection(modal: HTMLElement): void {
    const checked  = Array.from(modal.querySelectorAll<HTMLInputElement>('input[type="checkbox"]:checked'));
    const count    = checked.length;
    const btn      = modal.querySelector<HTMLButtonElement>('.mngt-dm-modal-btn')!;
    const groupDiv = modal.querySelector<HTMLElement>('.mngt-dm-modal-group-name')!;
    const countDiv = modal.querySelector<HTMLElement>('.mngt-dm-modal-count')!;

    btn.disabled    = count === 0;
    groupDiv.hidden = count < 2;
    countDiv.hidden = count === 0;

    if (count > 0) {
      countDiv.textContent = `${count}/20 selecionados`;
      btn.textContent = count === 1 ? 'Abrir conversa' : 'Criar grupo';
    } else {
      btn.textContent = 'Criar conversa';
    }
  }

  private async submitNewDm(): Promise<void> {
    const modal = document.getElementById('mngt-dm-modal');
    if (!modal) return;

    const checked    = Array.from(modal.querySelectorAll<HTMLInputElement>('input[type="checkbox"]:checked'));
    if (checked.length === 0) return;

    const userIds    = checked.map((cb) => cb.value);
    const names      = checked.map((cb) => cb.dataset['name'] ?? '');
    const groupInput = modal.querySelector<HTMLInputElement>('.mngt-dm-modal-group-input');
    const groupName  = groupInput?.value.trim() ?? '';

    const btn = modal.querySelector<HTMLButtonElement>('.mngt-dm-modal-btn')!;
    btn.disabled    = true;
    btn.textContent = '...';

    try {
      let channelId: string;
      let channelType: string;
      const displayName = groupName || names.join(', ');

      // All DMs are created via Stream SDK (REST API can only update existing channels).
      if (!this.client) throw new Error('Stream client not ready');

      let sdkChannelId: string;
      if (userIds.length === 1) {
        // 1-on-1: deterministic ID = sorted member IDs joined by '--'
        const members = [this.currentUserIdValue, userIds[0]!].sort();
        sdkChannelId  = members.join('--');
        const ch = this.client.channel('messaging', sdkChannelId, { members });
        await ch.create();
      } else {
        // Group DM: use explicit ID so Stream creates a non-distinct channel (allows adding members later)
        const allMembers = [this.currentUserIdValue, ...userIds];
        sdkChannelId = `grp-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 7)}`;
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const chData: Record<string, any> = { members: allMembers };
        if (groupName) chData['name'] = groupName;
        const ch = this.client.channel('messaging', sdkChannelId, chData);
        await ch.create();
      }

      // Notify backend for company validation
      const res = await fetch(this.dmUrlValue, {
        method:      'POST',
        credentials: 'same-origin',
        headers: {
          'Content-Type': 'application/json',
          'Accept':       'application/json',
          'X-CSRF-Token': this.csrfToken(),
        },
        body: JSON.stringify({ channelId: sdkChannelId, userIds }),
      });
      if (!res.ok) {
        const errText = await res.text().catch(() => res.status.toString());
        console.error('[mngt:chat] submitNewDm failed', res.status, errText);
        btn.textContent = `Erro ${res.status}`;
        return;
      }
      ({ channelId, channelType } = await res.json() as { channelId: string; channelType: string });

      this.closeDmModal();
      document.dispatchEvent(new CustomEvent('mngt:chat-navigate', {
        detail: { channelId, channelType, displayName },
      }));
      void this.refreshChannels();
    } catch (err) {
      console.error('[mngt:chat] submitNewDm exception', err);
      btn.textContent = 'Erro';
    } finally {
      if (btn.textContent === '...') {
        btn.disabled    = false;
        btn.textContent = userIds.length === 1 ? 'Abrir conversa' : 'Criar grupo';
      } else {
        btn.disabled = false;
      }
    }
  }

  // ── Presence ───────────────────────────────────────────────────

  private async refreshPresence(dmChannels: AnyChannel[]): Promise<void> {
    if (!this.client) return;
    const partnerIds: string[] = [];
    for (const ch of dmChannels) {
      const others = (Object.values(ch.state.members) as AnyRecord[])
        .filter((m) => m['user_id'] !== this.currentUserIdValue);
      if (others.length === 1) {
        const uid = others[0]?.['user_id'] as string | undefined;
        if (uid) partnerIds.push(uid);
      }
    }
    if (partnerIds.length === 0) return;
    try {
      const result = await this.client.queryUsers(
        { id: { $in: partnerIds } } as Parameters<StreamChat['queryUsers']>[0],
        {},
        { presence: true },
      );
      result.users.forEach((u) => this.presenceMap.set(u.id, (u.online as boolean) ?? false));
      this.presenceMap.forEach((online, userId) => {
        this.dmsListTarget.querySelectorAll<HTMLElement>(`[data-presence-id="${userId}"]`).forEach((dot) => {
          dot.hidden = !online;
        });
      });
    } catch { /* non-fatal */ }
  }

  // ── helpers ────────────────────────────────────────────────────

  private csrfToken(): string {
    return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? '';
  }

  private esc(text: string): string {
    return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  private playSound(): void {
    try {
      if (!this.audioCtx) this.audioCtx = new AudioContext();
      const ctx  = this.audioCtx;
      const play = () => {
        const now = ctx.currentTime;
        [520, 680].forEach((freq, i) => {
          const osc  = ctx.createOscillator();
          const gain = ctx.createGain();
          osc.connect(gain);
          gain.connect(ctx.destination);
          osc.type = 'sine';
          osc.frequency.value = freq;
          const t0 = now + i * 0.14;
          gain.gain.setValueAtTime(0, t0);
          gain.gain.linearRampToValueAtTime(0.22, t0 + 0.01);
          gain.gain.exponentialRampToValueAtTime(0.001, t0 + 0.35);
          osc.start(t0);
          osc.stop(t0 + 0.35);
        });
      };
      if (ctx.state === 'suspended') ctx.resume().then(play).catch(() => {});
      else play();
    } catch { /* AudioContext indisponível */ }
  }

  private async requestNotificationPermission(): Promise<void> {
    if (!('Notification' in window) || Notification.permission !== 'default') return;
    await Notification.requestPermission();
  }

  private async showBrowserNotification(sender: string): Promise<void> {
    if (!('Notification' in window) || Notification.permission !== 'granted') return;
    new Notification('Nova mensagem', {
      body: `${sender} enviou uma mensagem`,
      icon: '/favicon.ico',
      tag:  'mngt-chat',
    });
  }
}
