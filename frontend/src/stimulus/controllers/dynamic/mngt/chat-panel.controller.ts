import { Controller } from '@hotwired/stimulus';
import type { StreamChat, Channel, MessageResponse, Event as StreamEvent } from 'stream-chat';
import { signalClientReady } from './stream-client';
import { avatarColor as msgAvatarColorUtil, opAvatarUrl as opAvatarUrlUtil } from './utils/mngt-chat-utils';

interface StreamCredentials {
  token:  string;
  userId: string;
  apiKey: string;
  user:   { id: string; name: string; image?: string };
}

interface NavigateDetail {
  channelId:    string;
  channelType:  string;
  displayName?: string;
}

interface ReactionSummary { type: string; count: number; hasOwn: boolean; }

interface LinkPreview {
  url:       string;
  title?:    string;
  text?:     string;
  imageUrl?: string;
  siteName?: string;
}

interface RenderableMessage {
  id:               string;
  text:             string;
  authorName:       string;
  authorId:         string;
  avatarUrl?:       string;
  createdAt:        string;
  createdAtMs:      number;
  quotedMessage?:   { authorName: string; text: string };
  isDeleted?:       boolean;
  reactions:        ReactionSummary[];
  linkPreviews:     LinkPreview[];
  imageAttachments: Array<{ url: string; fallback: string }>;
}

interface PendingImage {
  id:         string;
  url:        string;
  filename:   string;
  previewUrl: string;
  uploading:  boolean;
  error?:     string;
}

// ── Emoji reactions ────────────────────────────────────────────
const EMOJI_REACTIONS = [
  { type: 'like',  emoji: '👍' },
  { type: 'love',  emoji: '❤️' },
  { type: 'haha',  emoji: '😂' },
  { type: 'wow',   emoji: '😮' },
  { type: 'sad',   emoji: '😢' },
  { type: 'fire',  emoji: '🔥' },
] as const;

const EMOJI_MAP: Record<string, string> = Object.fromEntries(
  EMOJI_REACTIONS.map(({ type, emoji }) => [type, emoji]),
);

// ── Avatar color (re-exported from shared utils) ───────────────
const msgAvatarColor = msgAvatarColorUtil;
const opAvatarUrl    = opAvatarUrlUtil;

function toRenderableMessage(msg: MessageResponse): RenderableMessage {
  const raw          = msg as unknown as Record<string, unknown>;
  const authorName   = (msg.user?.name as string | undefined) ?? (msg.user?.id ?? '?');
  const authorId     = msg.user?.id ?? '';
  const avatarUrl    = opAvatarUrl(msg.user?.id);
  const rawDate     = msg.created_at ? new Date(msg.created_at as string) : new Date();
  const createdAt   = rawDate.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
  const createdAtMs = rawDate.getTime();
  const quotedRaw    = raw['quoted_message'] as MessageResponse | undefined;
  const quotedMessage = quotedRaw
    ? { authorName: (quotedRaw.user?.name as string | undefined) ?? '?', text: quotedRaw.text ?? '' }
    : undefined;
  const isDeleted    = (raw['type'] as string | undefined) === 'deleted' || !!(raw['deleted_at']);
  const reactionCounts = (raw['reaction_counts'] ?? {}) as Record<string, number>;
  const ownSet         = new Set(((raw['own_reactions'] ?? []) as Array<{ type: string }>).map((r) => r.type));
  const reactions      = Object.entries(reactionCounts).map(([type, count]) => ({ type, count, hasOwn: ownSet.has(type) }));
  const attachments    = (raw['attachments'] ?? []) as Array<Record<string, unknown>>;
  const linkPreviews: LinkPreview[] = attachments
    .filter((a) => a['og_scrape_url'] || a['title_link'])
    .map((a) => ({
      url:      ((a['title_link'] ?? a['og_scrape_url']) as string | undefined) ?? '',
      title:    a['title']    as string | undefined,
      text:     a['text']     as string | undefined,
      imageUrl: (a['image_url'] ?? a['thumb_url']) as string | undefined,
      siteName: (a['author_name'] ?? a['footer'])  as string | undefined,
    }))
    .filter((p) => !!p.url && /^https?:\/\//.test(p.url));
  const imageAttachments = attachments
    .filter((a) => a['type'] === 'image' && a['image_url'])
    .map((a) => ({ url: a['image_url'] as string, fallback: (a['fallback'] as string | undefined) ?? 'imagem' }));

  return { id: msg.id ?? '', text: msg.text ?? '', authorName, authorId, avatarUrl, createdAt, createdAtMs, quotedMessage, isDeleted, reactions, linkPreviews, imageAttachments };
}

type MemberLike = { user_id?: string; user?: { name?: string; id?: string; image?: string } };

interface StreamUser {
  id:        string;
  name:      string;
  avatarUrl?: string;
}

export default class MngtChatPanelController extends Controller<HTMLElement> {
  static targets = ['panel', 'container', 'loading', 'error', 'button', 'badge', 'iconExpand', 'iconCompress'];
  static values  = {
    tokenUrl: String, usersUrl: String, groupMembersUrl: String,
    isAdmin: Boolean, canSeeAll: Boolean, companySlug: String, companiesMap: String,
  };

  declare panelTarget:         HTMLElement;
  declare containerTarget:     HTMLElement;
  declare loadingTarget:       HTMLElement;
  declare errorTarget:         HTMLElement;
  declare buttonTarget:        HTMLButtonElement;
  declare badgeTarget:         HTMLElement;
  declare iconExpandTarget:    HTMLElement;
  declare iconCompressTarget:  HTMLElement;
  declare tokenUrlValue:        string;
  declare usersUrlValue:        string;
  declare groupMembersUrlValue: string;
  declare isAdminValue:         boolean;
  declare canSeeAllValue:       boolean;
  declare companySlugValue:     string;
  declare companiesMapValue:    string;

  private streamClient:    StreamChat | null = null;
  private activeChannel:   Channel   | null = null;
  private currentUserId    = '';
  private maximized        = false;
  private ready            = false;
  private pendingNavigate: NavigateDetail | null = null;

  private typingUsers:    Map<string, string>  = new Map();
  private typingTimer:    ReturnType<typeof setTimeout> | null = null;
  private replyToMessage: MessageResponse | null = null;
  private pendingImages:  PendingImage[] = [];
  private presenceMap:    Map<string, boolean>  = new Map();
  private loadingOlder    = false;
  private hasMoreMsgs     = true;
  private currentUserName = '';
  private newMsgCount     = 0;
  private isJumpMode           = false;
  private searchDebounce:       ReturnType<typeof setTimeout> | null = null;
  private globalSearchDebounce: ReturnType<typeof setTimeout> | null = null;
  private channelNameMap:        Map<string, string> = new Map();
  private loadedChannels:        Channel[]           = [];
  private listNotifHandler:  ((e: StreamEvent) => void) | null = null;
  private listAddedHandler:  ((e: StreamEvent) => void) | null = null;
  private notifBadgeHandler: ((e: StreamEvent) => void) | null = null;
  private totalUnread        = 0;

  private readonly onUnreadChanged = (e: Event): void => {
    const { total } = (e as CustomEvent<{ total: number }>).detail;
    this.totalUnread = total;
    if (this.panelTarget.hidden) {
      this.badgeTarget.hidden      = total === 0;
      this.badgeTarget.textContent = total > 99 ? '99+' : String(total);
    }
  };
  private currentMessagesEl: HTMLElement | null = null;
  private openSeq = 0;

  private readonly onMessagesScroll = (): void => {
    const c = this.containerTarget.querySelector<HTMLElement>('#mngt-stream-messages');
    if (!c) return;
    if (!this.loadingOlder && this.hasMoreMsgs && c.scrollTop < 80) void this.loadOlderMessages();
    const atBottom = c.scrollHeight - c.scrollTop - c.clientHeight < 100;
    const btn   = this.containerTarget.querySelector<HTMLElement>('#mngt-scroll-to-bottom');
    const badge = this.containerTarget.querySelector<HTMLElement>('#mngt-scroll-badge');
    if (btn) btn.hidden = atBottom;
    if (atBottom && badge) { this.newMsgCount = 0; badge.hidden = true; badge.textContent = '0'; }
  };

  connect(): void {
    document.addEventListener('mngt:chat-navigate',   this.handleNavigate);
    document.addEventListener('mngt:unread-changed',  this.onUnreadChanged);
    void this.setup();
  }

  disconnect(): void {
    document.removeEventListener('mngt:chat-navigate',  this.handleNavigate);
    document.removeEventListener('mngt:unread-changed', this.onUnreadChanged);
    this.streamClient?.off('user.presence.changed', this.onPresenceChanged);
    this.streamClient?.off('connection.changed', this.onConnectionChanged);
    this.unsubscribeListUpdates();
    this.unsubscribeBadgeUpdates();
    this.unsubscribeChannel();
    if (this.currentMessagesEl) {
      this.currentMessagesEl.removeEventListener('scroll', this.onMessagesScroll);
      this.currentMessagesEl = null;
    }
    this.activeChannel = null;
    this.ready         = false;
    this.streamClient  = null;
  }

  toggle(): void {
    this.panelTarget.hidden = !this.panelTarget.hidden;
    if (!this.panelTarget.hidden) {
      this.badgeTarget.hidden = true;
    } else {
      this.badgeTarget.hidden      = this.totalUnread === 0;
      this.badgeTarget.textContent = this.totalUnread > 99 ? '99+' : String(this.totalUnread);
    }
  }

  showChannelList(): void {
    this.unsubscribeChannel();
    this.activeChannel = null;
    this.renderChannelList();
  }

  toggleMaximize(): void {
    this.maximized = !this.maximized;
    this.panelTarget.classList.toggle('mngt-chat-panel--maximized', this.maximized);
    this.iconExpandTarget.hidden  =  this.maximized;
    this.iconCompressTarget.hidden = !this.maximized;
  }

  async sendMessage(event: Event): Promise<void> {
    event.preventDefault();
    if (!this.activeChannel) return;
    const input = this.containerTarget.querySelector<HTMLTextAreaElement>('#mngt-stream-input');
    const text  = input?.value.trim() ?? '';
    const readyImages = this.pendingImages.filter((i) => !i.uploading && !i.error && i.url);
    if ((!text || text.length > 10000) && readyImages.length === 0) return;

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const msgData: Record<string, any> = { text };
    if (this.replyToMessage) msgData['quoted_message_id'] = this.replyToMessage.id;
    if (text.includes('@todos')) {
      msgData['mentioned_users'] = (Object.values(this.activeChannel.state.members) as MemberLike[])
        .filter((m) => m.user_id !== this.currentUserId)
        .map((m) => m.user_id)
        .filter(Boolean);
    }
    if (readyImages.length > 0) {
      msgData['attachments'] = readyImages.map((img) => ({
        type: 'image',
        image_url: img.url,
        fallback: img.filename,
      }));
    }

    if (input) {
      input.value = '';
      input.style.height = 'auto';
      const sendBtn = this.containerTarget.querySelector<HTMLButtonElement>('.mngt-stream-send');
      if (sendBtn) sendBtn.disabled = true;
    }
    this.pendingImages.forEach((img) => URL.revokeObjectURL(img.previewUrl));
    this.pendingImages = [];
    this.renderPendingImages();
    this.closeMentionDropdown();
    this.cancelReply();
    if (this.typingTimer) { clearTimeout(this.typingTimer); this.typingTimer = null; }
    void this.activeChannel.stopTyping();
    await this.activeChannel.sendMessage(msgData);
  }

  // ── Stimulus action handlers ───────────────────────────────────

  handleTypingInput(event: Event): void {
    if (!this.activeChannel) return;
    const channel = this.activeChannel;
    const input = event.target as HTMLTextAreaElement;
    input.style.height = 'auto';
    input.style.height = `${Math.min(input.scrollHeight, 120)}px`;
    if (this.typingTimer) clearTimeout(this.typingTimer);
    void channel.keystroke();
    this.typingTimer = setTimeout(() => { void channel.stopTyping(); this.typingTimer = null; }, 3000);
    this.updateSendButton();
    const counter = this.containerTarget.querySelector<HTMLElement>('#mngt-char-counter');
    if (counter) {
      const len = input.value.length;
      counter.textContent  = len > 9000 ? `${len}/10000` : '';
      counter.className    = `mngt-char-counter${len > 9500 ? ' mngt-char-counter--warn' : ''}`;
    }
    this.handleMentionInput(input);
  }

  handleInputKeydown(event: KeyboardEvent): void {
    const dropdown = this.containerTarget.querySelector<HTMLElement>('#mngt-mention-dropdown');

    if (event.key === 'Enter' && !event.shiftKey) {
      if (dropdown) {
        const items = Array.from(dropdown.querySelectorAll<HTMLElement>('.mngt-mention-item'));
        const sel   = dropdown.querySelector<HTMLElement>('.mngt-mention-item--active') ?? items[0];
        if (sel) { event.preventDefault(); sel.click(); return; }
      }
      event.preventDefault();
      void this.sendMessage(new Event('submit'));
      return;
    }

    if (!dropdown) return;
    const items     = Array.from(dropdown.querySelectorAll<HTMLElement>('.mngt-mention-item'));
    const active    = dropdown.querySelector<HTMLElement>('.mngt-mention-item--active');
    const activeIdx = active ? items.indexOf(active) : -1;
    if (event.key === 'ArrowDown') {
      event.preventDefault();
      const next = items[activeIdx + 1] ?? items[0];
      active?.classList.remove('mngt-mention-item--active');
      next?.classList.add('mngt-mention-item--active');
    } else if (event.key === 'ArrowUp') {
      event.preventDefault();
      const prev = items[activeIdx - 1] ?? items[items.length - 1];
      active?.classList.remove('mngt-mention-item--active');
      prev?.classList.add('mngt-mention-item--active');
    } else if (event.key === 'Tab' && items.length > 0) {
      const sel = dropdown.querySelector<HTMLElement>('.mngt-mention-item--active') ?? items[0];
      if (sel) { event.preventDefault(); sel.click(); }
    } else if (event.key === 'Escape') {
      this.closeMentionDropdown();
    }
  }

  handleMessageAction(event: Event): void {
    const btn        = event.currentTarget as HTMLElement;
    const actionType = btn.dataset['actionType'];
    const messageId  = btn.dataset['messageId'] ?? '';
    if (actionType === 'reply')       this.startReply(messageId);
    if (actionType === 'edit')        this.startEdit(messageId);
    if (actionType === 'delete')      void this.doDeleteMessage(messageId);
    if (actionType === 'show-picker') this.toggleReactionPicker(messageId, btn);
    if (actionType === 'react')       void this.sendReaction(messageId, btn.dataset['reactionType'] ?? '');
    if (actionType === 'copy')        this.doCopyMessage(messageId);
  }

  toggleChannelMenu(): void {
    const menu = this.containerTarget.querySelector<HTMLElement>('#mngt-stream-menu');
    if (!menu) return;
    menu.hidden = !menu.hidden;
    if (!menu.hidden) {
      const close = (e: MouseEvent) => {
        if (!menu.contains(e.target as Node)) { menu.hidden = true; document.removeEventListener('click', close, true); }
      };
      setTimeout(() => document.addEventListener('click', close, true), 0);
    }
  }

  startRename(): void {
    const menu   = this.containerTarget.querySelector<HTMLElement>('#mngt-stream-menu');
    const nameEl = this.containerTarget.querySelector<HTMLElement>('.mngt-stream-header-name');
    if (!nameEl || !this.activeChannel) return;
    if (menu) menu.hidden = true;
    const original = nameEl.textContent ?? '';
    const input    = document.createElement('input');
    input.className = 'mngt-stream-rename-input';
    input.value     = original;
    input.maxLength = 80;
    nameEl.replaceWith(input);
    input.focus(); input.select();
    let done = false;
    const finish = () => { if (!done) { done = true; void this.doRename(input.value.trim(), original, input); } };
    const cancel = () => { if (!done) { done = true; this.restoreHeaderName(input, original); } };
    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter')  { e.preventDefault(); finish(); }
      if (e.key === 'Escape') { e.preventDefault(); cancel(); }
    });
    input.addEventListener('blur', finish);
  }

  scrollToBottomAction(): void {
    this.scrollToBottom();
    this.newMsgCount = 0;
    const badge = this.containerTarget.querySelector<HTMLElement>('#mngt-scroll-badge');
    if (badge) { badge.hidden = true; badge.textContent = '0'; }
    const btn = this.containerTarget.querySelector<HTMLElement>('#mngt-scroll-to-bottom');
    if (btn) btn.hidden = true;
  }

  toggleMemberList(): void {
    const panel = this.containerTarget.querySelector<HTMLElement>('#mngt-member-list');
    if (!panel) return;
    const opening = !!panel.hidden;
    panel.hidden = !opening;
    if (opening) {
      this.renderMemberList(panel);
      const wrap = this.containerTarget.querySelector<HTMLElement>('.mngt-stream-messages-wrap');
      if (wrap && !wrap.querySelector('.mngt-member-list-backdrop')) {
        const backdrop = document.createElement('div');
        backdrop.className = 'mngt-member-list-backdrop';
        backdrop.addEventListener('click', () => this.toggleMemberList());
        wrap.insertAdjacentElement('afterbegin', backdrop);
      }
    } else {
      this.containerTarget.querySelector('.mngt-member-list-backdrop')?.remove();
    }
    this.containerTarget.querySelector<HTMLElement>('#mngt-members-btn')
      ?.classList.toggle('mngt-stream-header-btn--active', opening);
  }

  toggleSearch(): void {
    const overlay = this.containerTarget.querySelector<HTMLElement>('#mngt-search-overlay');
    if (!overlay) return;
    const opening = overlay.hidden;
    overlay.hidden = !opening;
    if (opening) {
      overlay.querySelector<HTMLInputElement>('.mngt-search-overlay-input')?.focus();
    } else {
      this.clearSearch();
    }
    this.containerTarget.querySelector<HTMLElement>('#mngt-search-btn')
      ?.classList.toggle('mngt-stream-header-btn--active', opening);
  }

  handleSearchInput(event: Event): void {
    const query = (event.target as HTMLInputElement).value.trim();
    if (this.searchDebounce) clearTimeout(this.searchDebounce);
    const resultsEl = this.containerTarget.querySelector<HTMLElement>('#mngt-search-results');
    if (!resultsEl) return;
    if (!query) {
      resultsEl.innerHTML = '<div class="mngt-search-hint">Digite para buscar mensagens</div>';
      return;
    }
    resultsEl.innerHTML = '<div class="mngt-search-hint">Buscando…</div>';
    this.searchDebounce = setTimeout(() => void this.doSearch(query), 400);
  }

  clearSearchAction(): void {
    const overlay = this.containerTarget.querySelector<HTMLElement>('#mngt-search-overlay');
    if (overlay) overlay.hidden = true;
    this.clearSearch();
    this.containerTarget.querySelector<HTMLElement>('#mngt-search-btn')
      ?.classList.remove('mngt-stream-header-btn--active');
  }

  handleSearchResultClick(event: Event): void {
    const btn = event.currentTarget as HTMLElement;
    const messageId = btn.dataset['messageId'];
    if (!messageId) return;
    const overlay = this.containerTarget.querySelector<HTMLElement>('#mngt-search-overlay');
    if (overlay) overlay.hidden = true;
    this.containerTarget.querySelector<HTMLElement>('#mngt-search-btn')
      ?.classList.remove('mngt-stream-header-btn--active');
    void this.jumpToMessage(messageId);
  }

  returnToLive(): void {
    this.isJumpMode = false;
    const jumpBar = this.containerTarget.querySelector<HTMLElement>('#mngt-jump-mode-bar');
    if (jumpBar) jumpBar.hidden = true;
    if (this.activeChannel) {
      const type = this.activeChannel.type;
      const id   = this.activeChannel.id ?? '';
      const data = this.activeChannel.data as Record<string, unknown> | undefined;
      const name = (data?.['name'] as string | undefined);
      void this.openChannel(type, id, name);
    }
  }

  toggleMuteChannel(): void {
    if (!this.activeChannel) return;
    const key    = `mngt_muted_${this.activeChannel.id}`;
    const muted  = localStorage.getItem(key) === 'true';
    try {
      if (muted) localStorage.removeItem(key);
      else       localStorage.setItem(key, 'true');
    } catch { /* storage unavailable */ }
    const btn = this.containerTarget.querySelector<HTMLElement>('#mngt-mute-btn');
    if (btn) {
      btn.classList.toggle('mngt-stream-header-btn--active', !muted);
      btn.title = muted ? 'Silenciar canal' : 'Ativar notificações';
    }
  }

  // ── Private: setup & channel ───────────────────────────────────

  private readonly handleNavigate = (event: Event): void => {
    const detail = (event as CustomEvent<NavigateDetail>).detail;
    this.panelTarget.hidden = false;
    if (this.ready) void this.openChannel(detail.channelType, detail.channelId, detail.displayName);
    else this.pendingNavigate = detail;
  };

  private async setup(attempt = 1): Promise<void> {
    try {
      const response = await fetch(this.tokenUrlValue, {
        headers: { 'X-CSRF-Token': this.csrfToken(), 'Accept': 'application/json' },
        credentials: 'same-origin',
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const creds = await response.json() as StreamCredentials;
      this.currentUserId   = creds.userId;
      this.currentUserName = creds.user.name ?? '';

      // Lazy-load the Stream SDK only when the chat is actually used
      const { StreamChat } = await import('stream-chat');
      const client = StreamChat.getInstance(creds.apiKey);
      if (client.userID !== creds.userId) {
        if (client.userID) await client.disconnectUser().catch(() => {});
        await client.connectUser(creds.user, creds.token);
      }
      this.streamClient = client;
      this.subscribeBadgeUpdates();
      signalClientReady(client);
      client.on('user.presence.changed', this.onPresenceChanged);
      client.on('connection.changed',    this.onConnectionChanged);
      this.loadingTarget.hidden   = true;
      this.containerTarget.hidden = false;
      this.ready = true;
      this.renderPlaceholder();
      if (this.pendingNavigate) {
        const p = this.pendingNavigate; this.pendingNavigate = null;
        void this.openChannel(p.channelType, p.channelId, p.displayName);
      }
    } catch (err) {
      console.error('[mngt:chat] setup failed', err);
      // Auto-retry with back-off (up to 3 attempts)
      if (attempt < 3) {
        const delay = attempt * 3000;
        setTimeout(() => void this.setup(attempt + 1), delay);
        return;
      }
      this.loadingTarget.hidden = true;
      this.showError();
    }
  }

  private showError(): void {
    const btn = document.createElement('button');
    btn.className   = 'mngt-chat-retry-btn';
    btn.textContent = 'Tentar novamente';
    btn.addEventListener('click', () => {
      this.errorTarget.hidden   = true;
      this.loadingTarget.hidden = false;
      void this.setup();
    });
    this.errorTarget.innerHTML = '<span>Erro ao conectar ao chat.</span>';
    this.errorTarget.appendChild(btn);
    this.errorTarget.hidden = false;
  }

  private async openChannel(type: string, id: string, displayName?: string, jumpToId?: string): Promise<void> {
    if (!this.streamClient) return;
    this.unsubscribeListUpdates();
    this.unsubscribeChannel();

    // Monotonic counter: if another openChannel() starts before this one settles,
    // the seq check below aborts the stale call and removes its orphan listeners.
    const seq = ++this.openSeq;

    this.typingUsers.clear();
    this.replyToMessage = null;
    this.loadingOlder   = false;
    this.hasMoreMsgs    = true;
    this.newMsgCount    = 0;
    this.isJumpMode     = false;

    const channel = this.streamClient.channel(type, id);
    channel.on('message.new',      this.onNewMessage);
    channel.on('message.updated',  this.onMessageUpdated);
    channel.on('message.deleted',  this.onMessageDeleted);
    channel.on('typing.start',     this.onTypingStart);
    channel.on('typing.stop',      this.onTypingStop);
    channel.on('reaction.new',     this.onReactionEvent);
    channel.on('reaction.deleted', this.onReactionEvent);

    await channel.watch();

    if (seq !== this.openSeq) {
      // A newer openChannel() call took over — clean up orphan listeners and bail.
      channel.off('message.new',      this.onNewMessage);
      channel.off('message.updated',  this.onMessageUpdated);
      channel.off('message.deleted',  this.onMessageDeleted);
      channel.off('typing.start',     this.onTypingStart);
      channel.off('typing.stop',      this.onTypingStop);
      channel.off('reaction.new',     this.onReactionEvent);
      channel.off('reaction.deleted', this.onReactionEvent);
      return;
    }

    await channel.markRead().catch(() => {});
    this.activeChannel = channel;
    this.renderChannel(channel, displayName);
    document.dispatchEvent(new CustomEvent('mngt:channel-read', { detail: { channelId: id } }));
    if (jumpToId) void this.jumpToMessage(jumpToId);

    // Query presence for DM members only (team channels have too many members)
    if (type === 'messaging' && this.streamClient) {
      const memberIds = (Object.values(channel.state.members) as MemberLike[])
        .map((m) => m.user_id)
        .filter((uid): uid is string => !!uid && uid !== this.currentUserId);
      if (memberIds.length > 0) {
        void this.streamClient
          .queryUsers({ id: { $in: memberIds } } as Parameters<StreamChat['queryUsers']>[0], {}, { presence: true })
          .then((result) => {
            result.users.forEach((u) => this.presenceMap.set(u.id, (u.online as boolean) ?? false));
            this.updatePresenceDots();
          });
      }
    }
  }

  private unsubscribeChannel(): void {
    if (!this.activeChannel) return;
    this.activeChannel.off('message.new',     this.onNewMessage);
    this.activeChannel.off('message.updated', this.onMessageUpdated);
    this.activeChannel.off('message.deleted', this.onMessageDeleted);
    this.activeChannel.off('typing.start',    this.onTypingStart);
    this.activeChannel.off('typing.stop',     this.onTypingStop);
    this.activeChannel.off('reaction.new',    this.onReactionEvent);
    this.activeChannel.off('reaction.deleted', this.onReactionEvent);
  }

  // ── Stream events ──────────────────────────────────────────────

  private readonly onNewMessage = (event: StreamEvent): void => {
    if (!event.message) return;
    if (this.isJumpMode) return;
    const container = this.containerTarget.querySelector<HTMLElement>('#mngt-stream-messages');
    if (!container) return;

    const newMsg      = event.message;
    const newDate     = new Date((newMsg.created_at as string | undefined) ?? new Date().toISOString());
    const newAuthorId = newMsg.user?.id ?? '';
    const newTs       = newDate.getTime();

    const allEls      = container.querySelectorAll<HTMLElement>('[data-message-id]');
    const lastEl      = allEls[allEls.length - 1];
    const prevAuthorId = lastEl?.dataset['authorId'] ?? '';
    const prevTs       = parseInt(lastEl?.dataset['createdAt'] ?? '0', 10);
    const prevDate     = prevTs ? new Date(prevTs) : null;

    let html = '';
    if (!prevDate || !this.isSameDay(prevDate, newDate)) {
      html += this.dateSeparatorHtml(this.formatDateLabel(newDate));
    }
    const grouped = !!prevTs && !!prevDate && this.isSameDay(prevDate, newDate) &&
                    this.shouldGroup(prevAuthorId, prevTs, newAuthorId, newTs);
    html += this.messageHtml(toRenderableMessage(newMsg), grouped);
    container.insertAdjacentHTML('beforeend', html);

    const isOwnMessage = newAuthorId === this.currentUserId;
    const atBottom     = container.scrollHeight - container.scrollTop - container.clientHeight < 100;
    if (isOwnMessage || atBottom) {
      this.scrollToBottom();
      this.newMsgCount = 0;
      const badge = this.containerTarget.querySelector<HTMLElement>('#mngt-scroll-badge');
      if (badge) { badge.hidden = true; badge.textContent = '0'; }
    } else {
      this.newMsgCount++;
      const badge = this.containerTarget.querySelector<HTMLElement>('#mngt-scroll-badge');
      if (badge) { badge.hidden = false; badge.textContent = String(this.newMsgCount); }
    }
  };

  private readonly onMessageUpdated = (event: StreamEvent): void => {
    if (!event.message) return;
    const msgEl = this.containerTarget.querySelector<HTMLElement>(`[data-message-id="${event.message.id}"]`);
    if (!msgEl) return;
    const grouped = msgEl.classList.contains('mngt-stream-message--grouped');
    const temp = document.createElement('div');
    temp.innerHTML = this.messageHtml(toRenderableMessage(event.message), grouped);
    msgEl.replaceWith(temp.firstElementChild!);
    this.updatePresenceDots();
  };

  private readonly onMessageDeleted = (event: StreamEvent): void => {
    if (!event.message) return;
    const msgEl = this.containerTarget.querySelector<HTMLElement>(`[data-message-id="${event.message.id}"]`);
    if (!msgEl) return;
    const grouped = msgEl.classList.contains('mngt-stream-message--grouped');
    const raw  = { ...event.message, deleted_at: event.message.deleted_at ?? new Date().toISOString() };
    const temp = document.createElement('div');
    temp.innerHTML = this.messageHtml(toRenderableMessage(raw as MessageResponse), grouped);
    msgEl.replaceWith(temp.firstElementChild!);
  };

  private readonly onReactionEvent = (event: StreamEvent): void => {
    if (!event.message) return;
    const msgEl = this.containerTarget.querySelector<HTMLElement>(`[data-message-id="${event.message.id}"]`);
    if (!msgEl) return;
    const grouped = msgEl.classList.contains('mngt-stream-message--grouped');
    const temp = document.createElement('div');
    temp.innerHTML = this.messageHtml(toRenderableMessage(event.message), grouped);
    msgEl.replaceWith(temp.firstElementChild!);
    this.updatePresenceDots();
  };

  private readonly onTypingStart = (event: StreamEvent): void => {
    const user = event.user;
    if (!user || user.id === this.currentUserId) return;
    this.typingUsers.set(user.id, (user.name as string | undefined) ?? user.id);
    this.updateTypingIndicator();
  };

  private readonly onTypingStop = (event: StreamEvent): void => {
    const user = event.user;
    if (!user) return;
    this.typingUsers.delete(user.id);
    this.updateTypingIndicator();
  };

  private readonly onPresenceChanged = (event: StreamEvent): void => {
    const user = event.user;
    if (!user?.id) return;
    const online = (user.online as boolean) ?? false;
    this.presenceMap.set(user.id, online);
    this.containerTarget.querySelectorAll<HTMLElement>(`[data-presence-id="${user.id}"]`).forEach((dot) => {
      dot.hidden = !online;
    });
  };

  // ── Typing indicator ───────────────────────────────────────────

  private updateTypingIndicator(): void {
    const el    = this.containerTarget.querySelector<HTMLElement>('#mngt-typing-indicator');
    if (!el) return;
    const names = Array.from(this.typingUsers.values());
    if (names.length === 0) { el.hidden = true; el.textContent = ''; }
    else {
      el.hidden = false;
      el.textContent = names.length === 1
        ? `${names[0]} está digitando…`
        : names.length === 2
          ? `${names[0]} e ${names[1]} estão digitando…`
          : `${names.length} pessoas estão digitando…`;
    }
  }

  // ── Presence ───────────────────────────────────────────────────

  private updatePresenceDots(): void {
    this.presenceMap.forEach((online, userId) => {
      this.containerTarget.querySelectorAll<HTMLElement>(`[data-presence-id="${userId}"]`).forEach((dot) => {
        dot.hidden = !online;
      });
    });
  }

  // ── Reactions ──────────────────────────────────────────────────

  private toggleReactionPicker(messageId: string, btn: HTMLElement): void {
    const pickerId = `mngt-picker-${messageId}`;
    const existing = document.getElementById(pickerId);
    if (existing) { existing.remove(); return; }
    document.querySelectorAll('.mngt-reaction-picker').forEach((el) => el.remove());

    const msgEl = btn.closest<HTMLElement>('.mngt-stream-message');
    if (!msgEl) return;

    const picker = document.createElement('div');
    picker.id        = pickerId;
    picker.className = 'mngt-reaction-picker';
    picker.innerHTML = EMOJI_REACTIONS.map(({ type, emoji }) =>
      `<button class="mngt-reaction-pick-btn"
               data-action="click->mngt--chat-panel#handleMessageAction"
               data-action-type="react"
               data-message-id="${messageId}"
               data-reaction-type="${type}">${emoji}</button>`
    ).join('');
    msgEl.insertAdjacentElement('beforeend', picker);

    const close = (e: MouseEvent) => {
      if (!picker.contains(e.target as Node)) { picker.remove(); document.removeEventListener('mousedown', close, true); }
    };
    setTimeout(() => document.addEventListener('mousedown', close, true), 0);
  }

  private async sendReaction(messageId: string, type: string): Promise<void> {
    if (!this.activeChannel || !type) return;
    document.getElementById(`mngt-picker-${messageId}`)?.remove();

    const messages     = this.activeChannel.state.messages as unknown as MessageResponse[];
    const msg          = messages.find((m) => m.id === messageId);
    const ownReactions = ((msg as unknown as Record<string, unknown>)?.['own_reactions'] ?? []) as Array<{ type: string }>;
    const alreadyHas   = ownReactions.some((r) => r.type === type);

    if (alreadyHas) await this.activeChannel.deleteReaction(messageId, type);
    else            await this.activeChannel.sendReaction(messageId, { type });
  }

  // ── Edit / Delete / Reply ──────────────────────────────────────

  private startEdit(messageId: string): void {
    const messages = this.activeChannel?.state.messages as unknown as MessageResponse[] | undefined;
    const original = messages?.find((m) => m.id === messageId)?.text ?? '';
    const msgEl  = this.containerTarget.querySelector<HTMLElement>(`[data-message-id="${messageId}"]`);
    const textEl = msgEl?.querySelector<HTMLElement>('.mngt-stream-msg-text');
    if (!msgEl || !textEl) return;
    const textarea = document.createElement('textarea');
    textarea.className = 'mngt-stream-input mngt-msg-edit-input';
    textarea.value     = original;
    textarea.rows      = 2;
    textEl.replaceWith(textarea);
    textarea.focus();
    textarea.setSelectionRange(textarea.value.length, textarea.value.length);
    const hint = document.createElement('div');
    hint.className = 'mngt-edit-hint';
    hint.textContent = 'Enter para salvar · Esc para cancelar';
    textarea.insertAdjacentElement('afterend', hint);
    let done = false;
    const finish = () => {
      if (done) return; done = true;
      hint.remove();
      const newText = textarea.value.trim();
      if (newText && newText !== original) void this.streamClient?.updateMessage({ id: messageId, text: newText } as unknown as MessageResponse);
      else textarea.replaceWith(textEl);
    };
    const cancel = () => { if (!done) { done = true; hint.remove(); textarea.replaceWith(textEl); } };
    textarea.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); finish(); }
      if (e.key === 'Escape') cancel();
    });
    textarea.addEventListener('blur', finish);
  }

  private async doDeleteMessage(messageId: string): Promise<void> {
    if (!confirm('Apagar esta mensagem?')) return;
    await this.streamClient?.deleteMessage(messageId);
  }

  private startReply(messageId: string): void {
    const messages = this.activeChannel?.state.messages as unknown as MessageResponse[] | undefined;
    const msg      = messages?.find((m) => m.id === messageId);
    if (!msg) return;
    this.replyToMessage = msg;
    this.containerTarget.querySelector('#mngt-reply-preview')?.remove();
    const authorName = (msg.user?.name as string | undefined) ?? '?';
    const text       = msg.text ?? '';
    const preview    = document.createElement('div');
    preview.id        = 'mngt-reply-preview';
    preview.className = 'mngt-reply-preview';
    preview.innerHTML = `
      <span class="mngt-reply-preview-label">Respondendo a <strong>${this.escape(authorName)}</strong>: ${this.escape(text.substring(0, 70))}${text.length > 70 ? '…' : ''}</span>
      <button class="mngt-reply-preview-cancel" type="button" aria-label="Cancelar">×</button>`;
    preview.querySelector('.mngt-reply-preview-cancel')?.addEventListener('click', () => this.cancelReply());
    this.containerTarget.querySelector<HTMLElement>('.mngt-stream-form-wrap')?.insertAdjacentElement('beforebegin', preview);
    this.containerTarget.querySelector<HTMLTextAreaElement>('#mngt-stream-input')?.focus();
  }

  private cancelReply(): void {
    this.replyToMessage = null;
    this.containerTarget.querySelector('#mngt-reply-preview')?.remove();
  }

  // ── @mention ───────────────────────────────────────────────────

  private handleMentionInput(input: HTMLTextAreaElement): void {
    const pos   = input.selectionStart ?? input.value.length;
    const match = input.value.substring(0, pos).match(/@(\w*)$/);
    if (!match) { this.closeMentionDropdown(); return; }

    const query   = match[1]!.toLowerCase();
    const showAll = !query || 'todos'.startsWith(query);
    const members = (Object.values(this.activeChannel?.state.members ?? {}) as MemberLike[])
      .filter((m) => m.user_id !== this.currentUserId)
      .map((m) => ({ id: m.user_id ?? '', name: (m.user?.name ?? m.user_id ?? '').trim() }))
      .filter((m) => m.id && (!query || m.name.toLowerCase().includes(query)));

    if (!showAll && members.length === 0) { this.closeMentionDropdown(); return; }

    this.closeMentionDropdown();
    const dropdown = document.createElement('div');
    dropdown.id        = 'mngt-mention-dropdown';
    dropdown.className = 'mngt-mention-dropdown';

    const todosItem = showAll
      ? `<div class="mngt-mention-item mngt-mention-item--all" data-user-id="__todos__" data-user-name="todos">@todos <span class="mngt-mention-item-hint">— Todos no canal</span></div>`
      : '';
    dropdown.innerHTML = todosItem + members.slice(0, 8).map((m) =>
      `<div class="mngt-mention-item" data-user-id="${this.escape(m.id)}" data-user-name="${this.escape(m.name)}">@${this.escape(m.name)}</div>`
    ).join('');
    this.containerTarget.querySelector<HTMLElement>('.mngt-stream-form-wrap')?.insertAdjacentElement('afterbegin', dropdown);

    dropdown.querySelectorAll<HTMLElement>('.mngt-mention-item').forEach((item) => {
      item.addEventListener('mousedown', (e) => {
        e.preventDefault();
        const name    = item.dataset['userName'] ?? '';
        const pos2    = input.selectionStart ?? input.value.length;
        const newBef  = input.value.substring(0, pos2).replace(/@(\w*)$/, `@${name} `);
        input.value   = newBef + input.value.substring(pos2);
        input.selectionStart = input.selectionEnd = newBef.length;
        this.closeMentionDropdown();
        input.focus();
      });
    });
  }

  private closeMentionDropdown(): void {
    this.containerTarget.querySelector('#mngt-mention-dropdown')?.remove();
  }

  // ── Rendering ──────────────────────────────────────────────────

  private renderPlaceholder(): void {
    this.renderChannelList();
  }

  private renderChannelList(): void {
    this.containerTarget.innerHTML = `
      <div class="mngt-chat-list">
        <div class="mngt-skeleton-row" style="padding:8px 10px 6px"><div class="mngt-skeleton-text" style="height:26px;border-radius:5px;max-width:none;flex:1"></div></div>
        <div style="padding:10px 14px 4px"><div class="mngt-skeleton-label"></div></div>
        <div class="mngt-skeleton-row"><div class="mngt-skeleton-avatar" style="border-radius:3px;width:16px;height:16px"></div><div class="mngt-skeleton-text" style="max-width:100px"></div></div>
        <div class="mngt-skeleton-row" style="animation-delay:0.1s"><div class="mngt-skeleton-avatar" style="border-radius:3px;width:16px;height:16px"></div><div class="mngt-skeleton-text" style="max-width:140px"></div></div>
        <div class="mngt-skeleton-row" style="animation-delay:0.2s"><div class="mngt-skeleton-avatar" style="border-radius:3px;width:16px;height:16px"></div><div class="mngt-skeleton-text" style="max-width:80px"></div></div>
        <div style="padding:10px 14px 4px"><div class="mngt-skeleton-label" style="animation-delay:0.15s"></div></div>
        <div class="mngt-skeleton-row" style="animation-delay:0.05s"><div class="mngt-skeleton-avatar"></div><div class="mngt-skeleton-text" style="max-width:90px"></div></div>
        <div class="mngt-skeleton-row" style="animation-delay:0.15s"><div class="mngt-skeleton-avatar"></div><div class="mngt-skeleton-text" style="max-width:120px"></div></div>
        <div class="mngt-skeleton-row" style="animation-delay:0.25s"><div class="mngt-skeleton-avatar"></div><div class="mngt-skeleton-text" style="max-width:75px"></div></div>
      </div>`;
    void this.loadChannelList();
  }

  private async loadChannelList(): Promise<void> {
    const listEl = this.containerTarget.querySelector<HTMLElement>('.mngt-chat-list');
    if (!listEl || !this.streamClient) return;
    // Preserve any active global search so a background refresh doesn't reset it.
    const preservedSearch = listEl.querySelector<HTMLInputElement>('#mngt-global-search-input')?.value ?? '';
    try {
      const sort = [{ last_message_at: -1 }, { created_at: -1 }] as const;
      const opts  = { limit: 30, state: true, watch: false };
      const [team, dms] = await Promise.all([
        this.streamClient.queryChannels({ type: 'team', members: { $in: [this.currentUserId] } }, sort, opts),
        this.streamClient.queryChannels(
          { type: 'messaging', members: { $in: [this.currentUserId] } },
          sort, opts,
        ),
      ]);

      // Build channel name lookup for global search results
      this.channelNameMap.clear();
      this.loadedChannels = [...team, ...dms];
      this.loadedChannels.forEach((ch) => {
        const data = ch.data as Record<string, unknown> | undefined;
        let name: string;
        if (ch.type === 'messaging') {
          const others = (Object.values(ch.state.members) as MemberLike[])
            .filter((m) => m.user_id !== this.currentUserId);
          name = (data?.['name'] as string | undefined)
            ?? others.map((m) => m.user?.name ?? m.user_id ?? '?').join(', ')
            ?? ch.id ?? '';
        } else {
          name = (data?.['name'] as string | undefined) ?? ch.id ?? '';
        }
        this.channelNameMap.set(ch.id ?? '', name);
      });

      const dmsHtml  = dms.map((ch)  => this.renderListDmItem(ch)).join('');

      const plusSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="12" height="12" aria-hidden="true"><path d="M7.75 2a.75.75 0 0 1 .75.75V7h4.25a.75.75 0 0 1 0 1.5H8.5v4.25a.75.75 0 0 1-1.5 0V8.5H2.75a.75.75 0 0 1 0-1.5H7V2.75A.75.75 0 0 1 7.75 2Z"/></svg>`;
      const channelAddBtn = this.isAdminValue
        ? `<button class="mngt-sidebar-add" id="mngt-panel-new-channel" title="Novo canal" aria-label="Novo canal">${plusSvg}</button>`
        : '';
      const dmAddBtn = `<button class="mngt-sidebar-add" id="mngt-panel-new-dm" title="Nova conversa" aria-label="Nova conversa">${plusSvg}</button>`;

      // Build team channels HTML — group by company for users who can see all companies
      let teamSectionHtml: string;
      if (team.length === 0) {
        teamSectionHtml = '<span class="mngt-chat-list-empty">Nenhum canal</span>';
      } else if (this.canSeeAllValue) {
        const knownSlugs = new Set(Object.keys(this.companiesMapObj));
        const validChannels = team.filter((ch) => knownSlugs.has((ch.id ?? '').split('--')[0] ?? ''));
        const groups = new Map<string, Channel[]>();
        for (const ch of validChannels) {
          const company = this.companyNameFromChannelId(ch.id ?? '');
          if (!groups.has(company)) groups.set(company, []);
          groups.get(company)!.push(ch);
        }
        let html = '';
        groups.forEach((chs, companyName) => {
          html += `<div class="mngt-sidebar-company-group">
            <div class="mngt-sidebar-company-label">${this.escape(companyName)}</div>
            ${chs.map((ch) => this.renderListChannelItem(ch)).join('')}
          </div>`;
        });
        teamSectionHtml = html || '<span class="mngt-chat-list-empty">Nenhum canal</span>';
      } else {
        teamSectionHtml = team.map((ch) => this.renderListChannelItem(ch)).join('');
      }

      const searchIcon = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="13" height="13" aria-hidden="true"><path d="M10.68 11.74a6 6 0 0 1-7.922-8.982 6 6 0 0 1 8.982 7.922l3.04 3.04a.749.749 0 0 1-.326 1.275.749.749 0 0 1-.734-.215ZM11.5 7a4.499 4.499 0 1 0-8.997 0A4.499 4.499 0 0 0 11.5 7Z"/></svg>`;

      listEl.innerHTML = `
        <div class="mngt-global-search-wrap">
          <div class="mngt-global-search-bar">
            ${searchIcon}
            <input class="mngt-global-search-input" id="mngt-global-search-input"
                   type="search" placeholder="Buscar mensagens…" autocomplete="off">
          </div>
          <div class="mngt-global-search-results" id="mngt-global-search-results" hidden>
            <div class="mngt-search-hint">Digite para buscar em todos os canais</div>
          </div>
        </div>
        <div class="mngt-chat-list-section">
          <div class="mngt-chat-list-section-label">Canais${channelAddBtn}</div>
          ${teamSectionHtml}
          ${this.isAdminValue ? `<button class="mngt-sidebar-new-dm mngt-panel-new-channel-btn"><span class="mngt-sidebar-new-dm-plus">+</span> Novo canal</button>` : ''}
        </div>
        <div class="mngt-chat-list-section">
          <div class="mngt-chat-list-section-label">Mensagens Diretas${dmAddBtn}</div>
          ${dmsHtml || '<span class="mngt-chat-list-empty">Nenhuma conversa</span>'}
          <button class="mngt-sidebar-new-dm mngt-panel-new-dm-btn"><span class="mngt-sidebar-new-dm-plus">+</span> Nova mensagem</button>
        </div>`;

      // Global search input handler
      const globalInput = listEl.querySelector<HTMLInputElement>('#mngt-global-search-input');
      const globalResultsEl = listEl.querySelector<HTMLElement>('#mngt-global-search-results');
      if (globalInput && globalResultsEl) {
        globalInput.addEventListener('input', () => {
          const query = globalInput.value.trim();
          if (this.globalSearchDebounce) clearTimeout(this.globalSearchDebounce);
          if (!query) { globalResultsEl.hidden = true; return; }
          globalResultsEl.hidden = false;
          globalResultsEl.innerHTML = '<div class="mngt-search-hint">Buscando…</div>';
          this.globalSearchDebounce = setTimeout(() => void this.doGlobalSearch(query), 400);
        });

        globalResultsEl.addEventListener('click', (e) => {
          const btn = (e.target as HTMLElement).closest<HTMLElement>('[data-message-id]');
          if (!btn) return;
          const channelId   = btn.dataset['channelId']   ?? '';
          const channelType = btn.dataset['channelType']  ?? 'team';
          const channelName = btn.dataset['channelName'];
          const messageId   = btn.dataset['messageId']   ?? '';
          if (!channelId || !messageId) return;
          globalInput.value = '';
          globalResultsEl.hidden = true;
          void this.openChannel(channelType, channelId, channelName, messageId);
        });
      }

      listEl.querySelectorAll<HTMLElement>('[data-list-channel-id]').forEach((btn) => {
        btn.addEventListener('click', () => {
          listEl.querySelectorAll<HTMLElement>('.mngt-chat-list-item--active').forEach((b) => b.classList.remove('mngt-chat-list-item--active'));
          btn.classList.add('mngt-chat-list-item--active');
          const type = btn.dataset['listChannelType'] ?? 'team';
          const id   = btn.dataset['listChannelId']   ?? '';
          const name = btn.dataset['listChannelName'];
          void this.openChannel(type, id, name);
        });
      });

      listEl.querySelectorAll<HTMLElement>('#mngt-panel-new-channel, .mngt-panel-new-channel-btn').forEach((el) => {
        el.addEventListener('click', () => document.dispatchEvent(new CustomEvent('mngt:open-new-channel')));
      });
      listEl.querySelectorAll<HTMLElement>('#mngt-panel-new-dm, .mngt-panel-new-dm-btn').forEach((el) => {
        el.addEventListener('click', () => document.dispatchEvent(new CustomEvent('mngt:open-new-dm')));
      });

      // Restore search query if user was typing when a background refresh fired.
      if (preservedSearch) {
        const newInput    = listEl.querySelector<HTMLInputElement>('#mngt-global-search-input');
        const newResults  = listEl.querySelector<HTMLElement>('#mngt-global-search-results');
        if (newInput && newResults) {
          newInput.value   = preservedSearch;
          newResults.hidden = false;
          newResults.innerHTML = '<div class="mngt-search-hint">Buscando…</div>';
          void this.doGlobalSearch(preservedSearch);
        }
      }

      // Subscribe to global client events so the list refreshes when messages arrive.
      this.subscribeListUpdates();
      this.updateBadge();
    } catch (err) {
      console.error('[mngt:chat] loadChannelList failed', err);
      if (listEl) listEl.innerHTML = '<span class="mngt-chat-list-empty">Erro ao carregar canais</span>';
    }
  }

  private renderListChannelItem(ch: Channel): string {
    const data   = ch.data as Record<string, unknown> | undefined;
    const name   = (data?.['name'] as string | undefined) ?? ch.id ?? '';
    const unread = ch.countUnread();
    return `<button class="mngt-chat-list-item"
        data-list-channel-id="${this.escape(ch.id ?? '')}"
        data-list-channel-type="${ch.type}"
        data-list-channel-name="${this.escape(name)}">
      <span class="mngt-chat-list-hash">#</span>
      <span class="mngt-chat-list-name">${this.escape(name)}</span>
      ${unread > 0 ? `<span class="mngt-sidebar-badge">${unread > 99 ? '99+' : unread}</span>` : ''}
    </button>`;
  }

  private renderListDmItem(ch: Channel): string {
    const data         = ch.data as Record<string, unknown> | undefined;
    const otherMembers = (Object.values(ch.state.members) as MemberLike[])
      .filter((m) => m.user_id !== this.currentUserId);
    const isGroup = !/^op_\d+--op_\d+$/.test(ch.id ?? '');
    const name    = (data?.['name'] as string | undefined)
      ?? otherMembers.map((m) => m.user?.name ?? m.user_id ?? '?').join(', ')
      ?? ch.id ?? '';
    const unread  = ch.countUnread();
    const bg         = msgAvatarColor(name);
    const initial    = (name[0] ?? '?').toUpperCase();
    const dmPhotoUrl = !isGroup ? opAvatarUrl(otherMembers[0]?.user_id) : undefined;
    const dmPhoto    = dmPhotoUrl
      ? `<span style="position:absolute;inset:0;border-radius:50%;background:url('${this.escape(dmPhotoUrl)}') center/cover no-repeat"></span>`
      : '';
    const avatarHtml = isGroup
      ? `<span class="mngt-chat-list-avatar" style="background:${bg}">
           <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="12" height="12"><path d="M7 14s-1 0-1-1 1-4 5-4 5 3 5 4-1 1-1 1H7Zm4-6a3 3 0 1 0 0-6 3 3 0 0 0 0 6Z"/><path fill-rule="evenodd" d="M5.216 14A2.238 2.238 0 0 1 5 13c0-1.355.68-2.75 1.936-3.72A6.325 6.325 0 0 0 5 9c-4 0-5 3-5 4s1 1 1 1h4.216Z"/><path d="M4.5 8a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5Z"/></svg>
         </span>`
      : `<span class="mngt-chat-list-avatar" style="background:${bg};position:relative">${initial}${dmPhoto}</span>`;
    return `<button class="mngt-chat-list-item"
        data-list-channel-id="${this.escape(ch.id ?? '')}"
        data-list-channel-type="${ch.type}"
        data-list-channel-name="${this.escape(name)}">
      ${avatarHtml}
      <span class="mngt-chat-list-name">${this.escape(name)}</span>
      ${unread > 0 ? `<span class="mngt-sidebar-badge">${unread > 99 ? '99+' : unread}</span>` : ''}
    </button>`;
  }

  private renderChannel(channel: Channel, displayName?: string): void {
    const members = Object.values(channel.state.members) as MemberLike[];
    // 1:1 DMs have a deterministic ID like "op_5--op_10"; groups have a Stream-assigned ID
    const is1on1  = channel.type === 'messaging' && /^op_\d+--op_\d+$/.test(channel.id ?? '');
    const isGroup = channel.type === 'messaging' && !is1on1;
    let name: string;
    if (displayName) {
      name = displayName;
    } else if (channel.type === 'messaging') {
      const other = members.find((m) => m.user_id !== this.currentUserId);
      name        = other?.user?.name ?? other?.user?.id ?? channel.id ?? '';
    } else {
      const channelData = channel.data as Record<string, unknown> | undefined;
      name              = (channelData?.['name'] as string | undefined) ?? channel.id ?? '';
    }

    const muted = this.isChannelMuted();

    const searchBtn = `
      <button class="mngt-stream-header-btn" id="mngt-search-btn"
              data-action="click->mngt--chat-panel#toggleSearch" aria-label="Buscar" title="Buscar mensagens">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="13" height="13"><path d="M10.68 11.74a6 6 0 0 1-7.922-8.982 6 6 0 0 1 8.982 7.922l3.04 3.04a.749.749 0 0 1-.326 1.275.749.749 0 0 1-.734-.215ZM11.5 7a4.499 4.499 0 1 0-8.997 0A4.499 4.499 0 0 0 11.5 7Z"/></svg>
      </button>`;

    const muteBtn = `
      <button class="mngt-stream-header-btn${muted ? ' mngt-stream-header-btn--active' : ''}" id="mngt-mute-btn"
              data-action="click->mngt--chat-panel#toggleMuteChannel" aria-label="Silenciar"
              title="${muted ? 'Ativar notificações' : 'Silenciar canal'}">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="13" height="13"><path d="M8 2.81v10.38c0 .67-.81 1-1.28.53L3 10H1a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1h2l3.72-3.72C7.19 1.81 8 2.14 8 2.81ZM13.5 8c0 1.71-.9 3.22-2.26 4.08a.5.5 0 0 1-.74-.43V4.35a.5.5 0 0 1 .74-.43C12.6 4.78 13.5 6.29 13.5 8Z"/></svg>
      </button>`;

    const membersBtn = (channel.type !== 'messaging' || isGroup) ? `
      <button class="mngt-stream-header-btn" id="mngt-members-btn"
              data-action="click->mngt--chat-panel#toggleMemberList" aria-label="Membros" title="Ver membros">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="13" height="13"><path d="M2 5.5a3.5 3.5 0 1 1 5.898 2.549 5.508 5.508 0 0 1 3.034 4.084.75.75 0 1 1-1.482.235 4 4 0 0 0-7.9 0 .75.75 0 0 1-1.482-.236A5.507 5.507 0 0 1 3.102 8.05 3.493 3.493 0 0 1 2 5.5ZM11 4a3.001 3.001 0 0 1 2.22 5.018 5.01 5.01 0 0 1 2.56 3.012.749.749 0 0 1-.885.954.752.752 0 0 1-.549-.514 3.507 3.507 0 0 0-2.522-2.372.75.75 0 0 1-.574-.73v-.352a.75.75 0 0 1 .416-.672A1.5 1.5 0 0 0 11 5.5.75.75 0 0 1 11 4Zm-5.5-.5a2 2 0 1 0-.001 3.999A2 2 0 0 0 5.5 3.5Z"/></svg>
      </button>` : '';

    const menuBtn = channel.type === 'messaging' ? `
      <button class="mngt-stream-header-btn" data-action="click->mngt--chat-panel#toggleChannelMenu" aria-label="Opções">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="14" height="14"><path d="M8 9a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3ZM1.5 9a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3Zm13 0a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3Z"/></svg>
      </button>
      <div class="mngt-stream-menu" id="mngt-stream-menu" hidden>
        <button data-action="click->mngt--chat-panel#openAddMemberModal">Adicionar membro</button>
        ${isGroup ? '<button data-action="click->mngt--chat-panel#startRename">Renomear grupo</button>' : ''}
      </div>` : '';

    const backBtn = `<button class="mngt-chat-back-btn" data-action="click->mngt--chat-panel#showChannelList" aria-label="Voltar"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="14" height="14"><path d="M9.78 12.78a.75.75 0 0 1-1.06 0L4.47 8.53a.75.75 0 0 1 0-1.06l4.25-4.25a.751.751 0 0 1 1.042.018.751.751 0 0 1 .018 1.042L6.06 8l3.72 3.72a.75.75 0 0 1 0 1.06Z"/></svg></button>`;

    const messages = channel.state.messages as unknown as MessageResponse[];
    this.containerTarget.innerHTML = `
      <div class="mngt-stream-header">
        ${backBtn}<span class="mngt-stream-header-name">${this.escape(name)}</span>
        ${searchBtn}${muteBtn}${membersBtn}${menuBtn}
      </div>
      <div id="mngt-search-overlay" class="mngt-search-overlay" hidden>
        <div class="mngt-search-overlay-bar">
          <input class="mngt-search-overlay-input" type="search" placeholder="Buscar mensagens…" autocomplete="off"
                 data-action="input->mngt--chat-panel#handleSearchInput">
          <button class="mngt-search-close" data-action="click->mngt--chat-panel#clearSearchAction" aria-label="Fechar">×</button>
        </div>
        <div class="mngt-search-results" id="mngt-search-results">
          <div class="mngt-search-hint">Digite para buscar mensagens</div>
        </div>
      </div>
      <div id="mngt-jump-mode-bar" class="mngt-jump-mode-bar" hidden>
        <span>Visualizando mensagens antigas</span>
        <button class="mngt-jump-mode-return" data-action="click->mngt--chat-panel#returnToLive">Ir para mensagens recentes ↓</button>
      </div>
      <div class="mngt-stream-messages-wrap">
        <div class="mngt-stream-messages" id="mngt-stream-messages">
          ${this.renderMessageList(messages)}
        </div>
        <button class="mngt-scroll-to-bottom" id="mngt-scroll-to-bottom" hidden
                data-action="click->mngt--chat-panel#scrollToBottomAction" aria-label="Ir para o fim">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="12" height="12"><path d="M4.53 4.75a.75.75 0 0 0-1.06 1.06l4 4a.75.75 0 0 0 1.06 0l4-4a.75.75 0 0 0-1.06-1.06L8 8.19 4.53 4.75Z"/></svg>
          <span class="mngt-scroll-badge" id="mngt-scroll-badge" hidden>0</span>
        </button>
        <div class="mngt-member-list" id="mngt-member-list" hidden></div>
      </div>
      <div class="mngt-typing-indicator" id="mngt-typing-indicator" hidden></div>
      <div class="mngt-stream-form-wrap" id="mngt-stream-form-wrap"
           data-action="dragover->mngt--chat-panel#handleDragOver dragenter->mngt--chat-panel#handleDragEnter dragleave->mngt--chat-panel#handleDragLeave drop->mngt--chat-panel#handleDrop">
        <div class="mngt-drop-overlay" id="mngt-drop-overlay" hidden aria-hidden="true">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="24" height="24"><path d="M2.75 14A1.75 1.75 0 0 1 1 12.25v-2.5a.75.75 0 0 1 1.5 0v2.5c0 .138.112.25.25.25h10.5a.25.25 0 0 0 .25-.25v-2.5a.75.75 0 0 1 1.5 0v2.5A1.75 1.75 0 0 1 13.25 14Z"/><path d="M7.25 7.689V2a.75.75 0 0 1 1.5 0v5.689l1.97-1.97a.749.749 0 1 1 1.06 1.06l-3.25 3.25a.749.749 0 0 1-1.06 0L4.22 6.779a.749.749 0 1 1 1.06-1.06l1.97 1.97Z"/></svg>
          <span>Soltar para enviar</span>
        </div>
        <div class="mngt-stream-attachments" id="mngt-stream-attachments"></div>
        <form class="mngt-stream-form" data-action="submit->mngt--chat-panel#sendMessage">
          <div class="mngt-attach-menu-wrap">
            <button class="mngt-stream-attach-btn" type="button"
                    data-action="click->mngt--chat-panel#toggleAttachMenu"
                    aria-label="Anexar" aria-haspopup="true">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="14" height="14"><path d="M7.75 2a.75.75 0 0 1 .75.75V7h4.25a.75.75 0 0 1 0 1.5H8.5v4.25a.75.75 0 0 1-1.5 0V8.5H2.75a.75.75 0 0 1 0-1.5H7V2.75A.75.75 0 0 1 7.75 2Z"/></svg>
            </button>
            <div class="mngt-attach-menu" id="mngt-attach-menu" hidden role="menu">
              <button class="mngt-attach-menu-item" type="button"
                      data-action="click->mngt--chat-panel#triggerFileInput"
                      role="menuitem">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="14" height="14"><path d="M4.502 9a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3M14.002 13a2 2 0 0 1-2 2h-10a2 2 0 0 1-2-2V5A2 2 0 0 1 2 3a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v8a2 2 0 0 1-1.998 2M14 2H4a1 1 0 0 0-1 1h9.002a2 2 0 0 1 2 2v7A1 1 0 0 0 15 11V3a1 1 0 0 0-1-1M2.002 4a1 1 0 0 0-1 1v8l2.646-2.354a.5.5 0 0 1 .63-.062l2.66 1.773 3.71-3.71a.5.5 0 0 1 .577-.094l1.777 1.947V5a1 1 0 0 0-1-1z"/></svg>
                <span>Imagem</span>
              </button>
            </div>
            <input type="file" accept="image/jpeg,image/png,image/webp,image/gif" multiple
                   id="mngt-stream-file-input" style="display:none"
                   data-action="change->mngt--chat-panel#handleFileSelect">
          </div>
          <div class="mngt-stream-input-wrap">
            <textarea class="mngt-stream-input" rows="1" placeholder="Escreva uma mensagem…"
                      autocomplete="off" id="mngt-stream-input" maxlength="10000"
                      data-action="input->mngt--chat-panel#handleTypingInput keydown->mngt--chat-panel#handleInputKeydown paste->mngt--chat-panel#handlePaste"></textarea>
            <span class="mngt-char-counter" id="mngt-char-counter"></span>
          </div>
          <button class="mngt-stream-send" type="submit" aria-label="Enviar" disabled>
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="14" height="14"><path d="M1.422 3.672a.75.75 0 0 1 .87-.49l12 3.5a.75.75 0 0 1 0 1.456l-12 3.5A.75.75 0 0 1 1 11v-3a.75.75 0 0 1 .662-.746L8.36 6.5.662 5.746A.75.75 0 0 1 1 5V3.672Z"/></svg>
          </button>
        </form>
      </div>`;

    this.insertUnreadDivider(channel);

    if (this.currentMessagesEl) {
      this.currentMessagesEl.removeEventListener('scroll', this.onMessagesScroll);
      this.currentMessagesEl = null;
    }
    const msgsEl = this.containerTarget.querySelector<HTMLElement>('#mngt-stream-messages');
    if (msgsEl) {
      this.currentMessagesEl = msgsEl;
      msgsEl.addEventListener('scroll', this.onMessagesScroll, { passive: true });
      const divider = msgsEl.querySelector<HTMLElement>('#mngt-unread-divider');
      if (divider) divider.scrollIntoView({ block: 'start' });
      else         this.scrollToBottom();
    }
  }

  private async doRename(newName: string, original: string, input: HTMLInputElement): Promise<void> {
    if (!newName || newName === original) { this.restoreHeaderName(input, original); return; }
    const res = await fetch(`/mngt/stream/channels/${this.activeChannel!.id}`, {
      method: 'PATCH', credentials: 'same-origin',
      headers: { 'Content-Type': 'application/json', 'Accept': 'application/json', 'X-CSRF-Token': this.csrfToken() },
      body: JSON.stringify({ name: newName, channel_type: this.activeChannel!.type }),
    }).catch(() => null);
    this.restoreHeaderName(input, res?.ok ? newName : original);
    if (res?.ok) document.dispatchEvent(new CustomEvent('mngt:channel-read'));
  }

  private restoreHeaderName(input: HTMLInputElement, name: string): void {
    const span = document.createElement('span');
    span.className = 'mngt-stream-header-name';
    span.textContent = name;
    input.replaceWith(span);
  }

  // ── Message HTML ───────────────────────────────────────────────

  private messageHtml(msg: RenderableMessage, grouped = false): string {
    const data       = `data-message-id="${msg.id}" data-author-id="${this.escape(msg.authorId)}" data-created-at="${msg.createdAtMs}"`;
    const mentionsMe = !msg.isDeleted && this.isMentioned(msg.text);
    const cls        = `mngt-stream-message${grouped ? ' mngt-stream-message--grouped' : ''}${mentionsMe ? ' mngt-stream-message--mention' : ''}`;
    const initial    = (msg.authorName[0] ?? '?').toUpperCase();
    const color      = msgAvatarColor(msg.authorName);
    const photoLayer = msg.avatarUrl && /^(https?:\/\/|\/)/.test(msg.avatarUrl)
      ? `<span style="position:absolute;inset:0;border-radius:50%;background:url('${this.escape(msg.avatarUrl)}') center/cover no-repeat"></span>`
      : '';
    const isOnline   = this.presenceMap.get(msg.authorId) ?? false;
    const presenceDot = msg.authorId !== this.currentUserId
      ? `<span class="mngt-status-dot" data-presence-id="${msg.authorId}" ${isOnline ? '' : 'hidden'}></span>`
      : '';
    const avatar = grouped
      ? `<div class="mngt-msg-avatar-wrap"><span class="mngt-stream-msg-time mngt-stream-msg-time--grouped">${msg.createdAt}</span></div>`
      : `<div class="mngt-msg-avatar-wrap">
          <span class="mngt-stream-msg-avatar" style="background:${color}">${initial}${photoLayer}</span>
          ${presenceDot}
        </div>`;

    const headerHtml = grouped ? '' : `
      <div class="mngt-stream-msg-header">
        <span class="mngt-stream-msg-author">${this.escape(msg.authorName)}</span>
        <span class="mngt-stream-msg-time">${msg.createdAt}</span>
      </div>`;

    if (msg.isDeleted) {
      return `<div class="${cls}" ${data}>
        ${avatar}
        <div class="mngt-stream-msg-content">
          ${headerHtml}
          <div class="mngt-stream-msg-text mngt-msg-deleted">Mensagem apagada</div>
        </div>
      </div>`;
    }

    const isMine     = msg.authorId === this.currentUserId;
    const quotedHtml = msg.quotedMessage ? `
      <div class="mngt-quoted-msg">
        <span class="mngt-quoted-msg-author">${this.escape(msg.quotedMessage.authorName)}</span>${this.escape(msg.quotedMessage.text.substring(0, 80))}${msg.quotedMessage.text.length > 80 ? '…' : ''}
      </div>` : '';

    const previewsHtml = msg.linkPreviews.map((p) => {
      const imgHtml = p.imageUrl
        ? `<div class="mngt-link-preview-img" style="background-image:url('${this.escape(p.imageUrl)}')"></div>`
        : '';
      return `<a class="mngt-link-preview" href="${this.escape(p.url)}" target="_blank" rel="noopener noreferrer">
        ${imgHtml}
        <div class="mngt-link-preview-body">
          ${p.siteName ? `<div class="mngt-link-preview-site">${this.escape(p.siteName)}</div>` : ''}
          ${p.title    ? `<div class="mngt-link-preview-title">${this.escape(p.title)}</div>` : ''}
          ${p.text     ? `<div class="mngt-link-preview-text">${this.escape(p.text)}</div>` : ''}
          <div class="mngt-link-preview-url">${this.escape(p.url)}</div>
        </div>
      </a>`;
    }).join('');

    const reactionsHtml = msg.reactions.length > 0 ? `
      <div class="mngt-reactions">
        ${msg.reactions.map(({ type, count, hasOwn }) => {
          const emoji = EMOJI_MAP[type] ?? type;
          return `<button class="mngt-reaction-btn ${hasOwn ? 'mngt-reaction-btn--own' : ''}"
                          data-action="click->mngt--chat-panel#handleMessageAction"
                          data-action-type="react"
                          data-message-id="${msg.id}"
                          data-reaction-type="${type}"
                          title="${type}">${emoji} <span>${count}</span></button>`;
        }).join('')}
      </div>` : '';

    const actionsHtml = `
      <div class="mngt-msg-actions">
        <button class="mngt-msg-action-btn" data-action="click->mngt--chat-panel#handleMessageAction" data-action-type="show-picker" data-message-id="${msg.id}" title="Reagir">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="11" height="11"><path d="M8 0a8 8 0 1 1 0 16A8 8 0 0 1 8 0ZM1.5 8a6.5 6.5 0 1 0 13 0 6.5 6.5 0 0 0-13 0Zm3.25 1.5a.75.75 0 0 1 1.06 1.06 3.25 3.25 0 0 0 4.38 0 .75.75 0 1 1 1.06 1.06 4.75 4.75 0 0 1-6.5 0 .75.75 0 0 1 0-1.06ZM5 7a1 1 0 1 1 0-2 1 1 0 0 1 0 2Zm6 0a1 1 0 1 1 0-2 1 1 0 0 1 0 2Z"/></svg>
        </button>
        <button class="mngt-msg-action-btn" data-action="click->mngt--chat-panel#handleMessageAction" data-action-type="reply" data-message-id="${msg.id}" title="Responder">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="11" height="11"><path d="M6.78 1.97a.75.75 0 0 1 0 1.06L3.81 6h6.44A5.75 5.75 0 0 1 16 11.75v1.5a.75.75 0 0 1-1.5 0v-1.5a4.25 4.25 0 0 0-4.25-4.25H3.81l2.97 2.97a.749.749 0 0 1-.326 1.275.749.749 0 0 1-.734-.215L1.47 7.28a.75.75 0 0 1 0-1.06l4.25-4.25a.75.75 0 0 1 1.06 0Z"/></svg>
        </button>
        <button class="mngt-msg-action-btn" data-action="click->mngt--chat-panel#handleMessageAction" data-action-type="copy" data-message-id="${msg.id}" title="Copiar">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="11" height="11"><path d="M0 6.75C0 5.784.784 5 1.75 5h1.5a.75.75 0 0 1 0 1.5h-1.5a.25.25 0 0 0-.25.25v7.5c0 .138.112.25.25.25h7.5a.25.25 0 0 0 .25-.25v-1.5a.75.75 0 0 1 1.5 0v1.5A1.75 1.75 0 0 1 9.25 16h-7.5A1.75 1.75 0 0 1 0 14.25Z"/><path d="M5 1.75C5 .784 5.784 0 6.75 0h7.5C15.216 0 16 .784 16 1.75v7.5A1.75 1.75 0 0 1 14.25 11h-7.5A1.75 1.75 0 0 1 5 9.25Zm1.75-.25a.25.25 0 0 0-.25.25v7.5c0 .138.112.25.25.25h7.5a.25.25 0 0 0 .25-.25v-7.5a.25.25 0 0 0-.25-.25Z"/></svg>
        </button>
        ${isMine ? `
        <button class="mngt-msg-action-btn" data-action="click->mngt--chat-panel#handleMessageAction" data-action-type="edit" data-message-id="${msg.id}" title="Editar">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="11" height="11"><path d="M11.013 1.427a1.75 1.75 0 0 1 2.474 0l1.086 1.086a1.75 1.75 0 0 1 0 2.474l-8.61 8.61c-.21.21-.47.364-.756.445l-3.251.93a.75.75 0 0 1-.927-.928l.929-3.25c.081-.286.235-.547.445-.758l8.61-8.61Zm.176 4.823L9.75 4.81l-6.286 6.287a.253.253 0 0 0-.064.108l-.558 1.953 1.953-.558a.253.253 0 0 0 .108-.064Zm1.238-3.763a.25.25 0 0 0-.354 0L10.811 3.75l1.439 1.44 1.263-1.263a.25.25 0 0 0 0-.354Z"/></svg>
        </button>
        <button class="mngt-msg-action-btn mngt-msg-action-btn--danger" data-action="click->mngt--chat-panel#handleMessageAction" data-action-type="delete" data-message-id="${msg.id}" title="Apagar">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" width="11" height="11"><path d="M11 1.75V3h2.25a.75.75 0 0 1 0 1.5H2.75a.75.75 0 0 1 0-1.5H5V1.75C5 .784 5.784 0 6.75 0h2.5C10.216 0 11 .784 11 1.75ZM4.496 6.675l.66 6.6a.25.25 0 0 0 .249.225h5.19a.25.25 0 0 0 .249-.225l.66-6.6a.75.75 0 0 1 1.492.149l-.66 6.6A1.748 1.748 0 0 1 10.595 15h-5.19a1.75 1.75 0 0 1-1.741-1.575l-.66-6.6a.75.75 0 1 1 1.492-.15ZM6.5 1.75V3h3V1.75a.25.25 0 0 0-.25-.25h-2.5a.25.25 0 0 0-.25.25Z"/></svg>
        </button>` : ''}
      </div>`;

    const imagesHtml = msg.imageAttachments.length > 0 ? (() => {
      const gridClass = msg.imageAttachments.length === 1 ? 'mngt-img-single' : 'mngt-img-grid';
      return `<div class="mngt-msg-images ${gridClass}">
        ${msg.imageAttachments.map((a) => `
          <a href="${this.escape(a.url)}" target="_blank" rel="noopener noreferrer">
            <img src="${this.escape(a.url)}" alt="${this.escape(a.fallback)}" loading="lazy" class="mngt-msg-image" />
          </a>`).join('')}
      </div>`;
    })() : '';

    return `
      <div class="${cls}" ${data}>
        ${avatar}
        <div class="mngt-stream-msg-content">
          ${headerHtml}
          ${quotedHtml}
          ${msg.text ? `<div class="mngt-stream-msg-text">${this.renderText(msg.text)}</div>` : ''}
          ${imagesHtml}
          ${previewsHtml}
          ${reactionsHtml}
        </div>
        ${actionsHtml}
      </div>`;
  }

  // ── Date separators, grouping, message list ────────────────────

  private isSameDay(a: Date, b: Date): boolean {
    return a.getFullYear() === b.getFullYear() &&
           a.getMonth()    === b.getMonth()    &&
           a.getDate()     === b.getDate();
  }

  private formatDateLabel(date: Date): string {
    const today     = new Date();
    const yesterday = new Date(today.getFullYear(), today.getMonth(), today.getDate() - 1);
    if (this.isSameDay(date, today))     return 'Hoje';
    if (this.isSameDay(date, yesterday)) return 'Ontem';
    return date.toLocaleDateString('pt-BR', { weekday: 'long', day: 'numeric', month: 'long' });
  }

  private shouldGroup(prevAuthorId: string, prevTs: number, currAuthorId: string, currTs: number): boolean {
    return !!prevAuthorId && prevAuthorId === currAuthorId && (currTs - prevTs) < 5 * 60 * 1000;
  }

  private dateSeparatorHtml(label: string): string {
    return `<div class="mngt-date-separator" aria-hidden="true"><span>${this.escape(label)}</span></div>`;
  }

  private renderMessageList(messages: MessageResponse[]): string {
    let html         = '';
    let lastDate: Date | null = null;
    let lastAuthorId = '';
    let lastTs       = 0;

    for (const msg of messages) {
      const date    = msg.created_at ? new Date(msg.created_at as string) : new Date();
      const authorId = msg.user?.id ?? '';
      const ts       = date.getTime();

      if (!lastDate || !this.isSameDay(lastDate, date)) {
        html += this.dateSeparatorHtml(this.formatDateLabel(date));
        lastAuthorId = '';
        lastTs       = 0;
      }

      const grouped = this.shouldGroup(lastAuthorId, lastTs, authorId, ts);
      html += this.messageHtml(toRenderableMessage(msg), grouped);

      lastDate     = date;
      lastAuthorId = authorId;
      lastTs       = ts;
    }
    return html;
  }

  // ── Pagination ─────────────────────────────────────────────────

  private async loadOlderMessages(): Promise<void> {
    if (!this.activeChannel || this.loadingOlder || !this.hasMoreMsgs) return;
    const container = this.containerTarget.querySelector<HTMLElement>('#mngt-stream-messages');
    if (!container) return;

    const firstId = container.querySelector<HTMLElement>('[data-message-id]')?.dataset['messageId'];
    if (!firstId) return;

    this.loadingOlder = true;
    const prevScrollHeight = container.scrollHeight;

    const loader = document.createElement('div');
    loader.id        = 'mngt-older-loader';
    loader.className = 'mngt-older-loader';
    loader.textContent = 'Carregando…';
    container.insertAdjacentElement('afterbegin', loader);

    try {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const result = await (this.activeChannel as any).query({
        messages: { limit: 25, id_lt: firstId },
        members:  { limit: 0 },
        watchers: { limit: 0 },
      }) as { messages: MessageResponse[] };

      loader.remove();
      const older = (result.messages ?? []) as MessageResponse[];

      if (older.length === 0) {
        this.hasMoreMsgs = false;
        const el = document.createElement('div');
        el.className   = 'mngt-no-more-messages';
        el.textContent = 'Início da conversa';
        container.insertAdjacentElement('afterbegin', el);
      } else {
        if (older.length < 25) this.hasMoreMsgs = false;
        container.insertAdjacentHTML('afterbegin', this.renderMessageList(older));
        container.scrollTop = container.scrollHeight - prevScrollHeight;
      }
    } catch {
      loader.remove();
    } finally {
      this.loadingOlder = false;
    }
  }

  private renderText(text: string): string {
    // Tokenize: code blocks and inline code are protected from markdown/URL processing
    const tokenRegex = /```([\s\S]*?)```|`([^`\n]+)`|https?:\/\/[^\s<>"]+/g;
    const parts: string[] = [];
    let lastIndex = 0;
    let match: RegExpExecArray | null;
    while ((match = tokenRegex.exec(text)) !== null) {
      if (match.index > lastIndex) parts.push(this.formatMarkdown(text.slice(lastIndex, match.index)));
      if (match[1] !== undefined) {
        const code = match[1].replace(/^\n/, '').replace(/\n$/, '');
        parts.push(`<pre class="mngt-code-block"><code>${this.escape(code)}</code></pre>`);
      } else if (match[2] !== undefined) {
        parts.push(`<code class="mngt-code-inline">${this.escape(match[2])}</code>`);
      } else {
        const esc = this.escape(match[0]);
        parts.push(`<a class="mngt-link" href="${esc}" target="_blank" rel="noopener noreferrer">${esc}</a>`);
      }
      lastIndex = match.index + match[0].length;
    }
    if (lastIndex < text.length) parts.push(this.formatMarkdown(text.slice(lastIndex)));
    return parts.join('');
  }

  private formatMarkdown(text: string): string {
    return this.escape(text)
      .replace(/\*\*\*(.+?)\*\*\*/g, '<strong><em>$1</em></strong>')
      .replace(/\*\*(.+?)\*\*/g,     '<strong>$1</strong>')
      .replace(/__(.+?)__/g,          '<u>$1</u>')
      .replace(/\*(.+?)\*/g,          '<em>$1</em>')
      .replace(/~~(.+?)~~/g,          '<s>$1</s>')
      .replace(/^&gt;\s?(.*)$/gm,     '<div class="mngt-blockquote">$1</div>')
      .replace(/@\[([^\]]+)\]/g,      '<strong class="mngt-mention">@$1</strong>')
      .replace(/@todos\b/g,           '<strong class="mngt-mention mngt-mention-all">@todos</strong>')
      .replace(/@(\w+)/g,             '<strong class="mngt-mention">@$1</strong>')
      .replace(/\n/g,                 '<br>');
  }

  // ── Unread divider ─────────────────────────────────────────────

  private insertUnreadDivider(channel: Channel): void {
    const container = this.containerTarget.querySelector<HTMLElement>('#mngt-stream-messages');
    if (!container) return;
    const readMap   = channel.state.read as Record<string, { last_read?: string | Date }>;
    const lastRead  = readMap[this.currentUserId]?.last_read;
    if (!lastRead) return;
    const lastReadMs = new Date(lastRead as string).getTime();
    const els        = Array.from(container.querySelectorAll<HTMLElement>('[data-message-id]'));
    const firstUnread = els.find((el) => {
      if (el.dataset['authorId'] === this.currentUserId) return false;
      return parseInt(el.dataset['createdAt'] ?? '0', 10) > lastReadMs;
    });
    if (!firstUnread) return;
    const div = document.createElement('div');
    div.id        = 'mngt-unread-divider';
    div.className = 'mngt-unread-divider';
    div.setAttribute('aria-hidden', 'true');
    div.innerHTML = '<span>Novas mensagens</span>';
    firstUnread.insertAdjacentElement('beforebegin', div);
  }

  // ── Mention detection ──────────────────────────────────────────

  private isMentioned(text: string): boolean {
    if (!this.currentUserName) return false;
    const lower     = text.toLowerCase();
    const name      = this.currentUserName.toLowerCase();
    const firstName = name.split(' ')[0] ?? name;
    return lower.includes(`@${firstName}`) || lower.includes(`@[${name}]`) || lower.includes('@todos');
  }

  // ── Mute ───────────────────────────────────────────────────────

  private isChannelMuted(): boolean {
    try { return localStorage.getItem(`mngt_muted_${this.activeChannel?.id}`) === 'true'; }
    catch { return false; }
  }

  // ── Copy message ───────────────────────────────────────────────

  private doCopyMessage(messageId: string): void {
    const messages = this.activeChannel?.state.messages as unknown as MessageResponse[] | undefined;
    const text     = messages?.find((m) => m.id === messageId)?.text;
    if (text) navigator.clipboard.writeText(text).catch(() => {});
  }

  // ── Member list ────────────────────────────────────────────────

  private renderMemberList(panel: HTMLElement): void {
    if (!this.activeChannel) return;
    const members = (Object.values(this.activeChannel.state.members) as MemberLike[])
      .filter((m) => !!m.user_id)
      .sort((a, b) => {
        const aOn = this.presenceMap.get(a.user_id!) ? 1 : 0;
        const bOn = this.presenceMap.get(b.user_id!) ? 1 : 0;
        return bOn - aOn;
      });

    const isGroupDm = this.activeChannel.type === 'messaging';

    panel.innerHTML = `
      <div class="mngt-member-list-header">
        <span>Membros (${members.length})</span>
        <button class="mngt-msg-action-btn" data-action="click->mngt--chat-panel#toggleMemberList" aria-label="Fechar">×</button>
      </div>
      ${isGroupDm ? `<button class="mngt-member-add-btn" data-action="click->mngt--chat-panel#openAddMemberModal">+ Adicionar membro</button>` : ''}
      ${members.map((m) => {
        const uid      = m.user_id!;
        const name     = m.user?.name ?? m.user?.id ?? uid;
        const initial  = (name[0] ?? '?').toUpperCase();
        const color    = msgAvatarColor(name);
        const isOnline = this.presenceMap.get(uid) ?? false;
        const memberPhotoUrl = opAvatarUrl(uid);
        const photo = memberPhotoUrl
          ? `<span style="position:absolute;inset:0;border-radius:50%;background:url('${this.escape(memberPhotoUrl)}') center/cover no-repeat"></span>`
          : '';
        return `<div class="mngt-member-item">
          <div class="mngt-msg-avatar-wrap">
            <span class="mngt-member-avatar" style="background:${color}">${initial}${photo}</span>
            <span class="mngt-status-dot mngt-member-dot" data-presence-id="${uid}" ${isOnline ? '' : 'hidden'}></span>
          </div>
          <span class="mngt-member-name${isOnline ? '' : ' mngt-member-name--offline'}">${this.escape(name)}</span>
        </div>`;
      }).join('')}`;
  }

  openAddMemberModal(): void {
    const menu = this.containerTarget.querySelector<HTMLElement>('#mngt-stream-menu');
    if (menu) menu.hidden = true;
    document.getElementById('mngt-add-member-modal')?.remove();
    if (!this.activeChannel) return;

    const currentMemberIds = new Set(
      (Object.values(this.activeChannel.state.members) as MemberLike[])
        .map((m) => m.user_id)
        .filter(Boolean) as string[],
    );

    const modal = document.createElement('div');
    modal.id        = 'mngt-add-member-modal';
    modal.className = 'mngt-dm-modal';
    modal.innerHTML = `
      <div class="mngt-dm-modal-backdrop"></div>
      <div class="mngt-dm-modal-body" role="dialog" aria-modal="true" aria-label="Adicionar membro">
        <div class="mngt-dm-modal-header">
          <span>Adicionar membro</span>
          <button class="mngt-dm-modal-close" aria-label="Fechar">×</button>
        </div>
        <input class="mngt-dm-modal-search" type="text" placeholder="Buscar usuário..." autocomplete="off" />
        <div class="mngt-dm-modal-users" id="mngt-add-member-users">
          <span class="mngt-dm-modal-empty">Carregando...</span>
        </div>
        <div class="mngt-dm-modal-footer">
          <button class="mngt-dm-modal-btn" disabled>Adicionar</button>
        </div>
      </div>`;

    document.body.appendChild(modal);

    const escHandler = (e: KeyboardEvent): void => {
      if (e.key === 'Escape') closeModal();
    };
    const closeModal = (): void => {
      document.removeEventListener('keydown', escHandler);
      document.getElementById('mngt-add-member-modal')?.remove();
    };

    document.addEventListener('keydown', escHandler);
    modal.querySelector('.mngt-dm-modal-backdrop')!.addEventListener('click', closeModal);
    modal.querySelector('.mngt-dm-modal-close')!.addEventListener('click', closeModal);

    let allUsers: StreamUser[] = [];

    const renderUsers = (query: string): void => {
      const container = document.getElementById('mngt-add-member-users');
      if (!container) return;
      const q        = query.toLowerCase().trim();
      const filtered = q ? allUsers.filter((u) => u.name.toLowerCase().includes(q)) : allUsers;
      if (filtered.length === 0) {
        container.innerHTML = '<span class="mngt-dm-modal-empty">Nenhum usuário encontrado</span>';
        return;
      }
      container.innerHTML = filtered.map((u) => {
        const initial    = (u.name[0] ?? '?').toUpperCase();
        const color      = msgAvatarColor(u.name);
        const photoLayer = u.avatarUrl
          ? `<span style="position:absolute;inset:0;border-radius:inherit;background:url('${this.escape(u.avatarUrl)}') center/cover no-repeat"></span>`
          : '';
        return `
          <label class="mngt-dm-modal-user">
            <input type="checkbox" value="${u.id}" />
            <span class="mngt-sidebar-avatar mngt-sidebar-avatar--sm" style="background:${color}">${initial}${photoLayer}</span>
            <span>${this.escape(u.name)}</span>
          </label>`;
      }).join('');
      container.querySelectorAll<HTMLInputElement>('input[type="checkbox"]').forEach((cb) => {
        cb.addEventListener('change', () => {
          const count = container.querySelectorAll<HTMLInputElement>('input[type="checkbox"]:checked').length;
          const btn   = modal.querySelector<HTMLButtonElement>('.mngt-dm-modal-btn')!;
          btn.disabled    = count === 0;
          btn.textContent = count > 1 ? `Adicionar (${count})` : 'Adicionar';
        });
      });
    };

    modal.querySelector<HTMLInputElement>('.mngt-dm-modal-search')!
      .addEventListener('input', (e) => renderUsers((e.target as HTMLInputElement).value));

    void fetch(this.usersUrlValue, { headers: { Accept: 'application/json' }, credentials: 'same-origin' })
      .then((res) => res.json() as Promise<StreamUser[]>)
      .then((users) => {
        allUsers = users.filter((u) => !currentMemberIds.has(u.id));
        renderUsers('');
      })
      .catch(() => {
        const container = document.getElementById('mngt-add-member-users');
        if (container) container.innerHTML = '<span class="mngt-dm-modal-empty">Erro ao carregar usuários</span>';
      });

    modal.querySelector<HTMLInputElement>('.mngt-dm-modal-search')!.focus();

    modal.querySelector('.mngt-dm-modal-btn')!.addEventListener('click', () => {
      const checked = Array.from(modal.querySelectorAll<HTMLInputElement>('input[type="checkbox"]:checked'));
      if (checked.length === 0 || !this.activeChannel) return;

      const userIds = checked.map((cb) => cb.value);
      const btn     = modal.querySelector<HTMLButtonElement>('.mngt-dm-modal-btn')!;
      btn.disabled = true;
      btn.textContent = 'Adicionando';
      btn.classList.add('is-loading');

      void fetch(this.groupMembersUrlValue, {
        method:      'POST',
        credentials: 'same-origin',
        headers: {
          'Content-Type': 'application/json',
          'Accept':       'application/json',
          'X-CSRF-Token': this.csrfToken(),
        },
        body: JSON.stringify({ channelId: this.activeChannel.id, userIds }),
      })
        .then(async (res) => {
          if (!res.ok) {
            const body = await res.json().catch(() => ({})) as { error?: string };
            throw new Error(body.error ?? `HTTP ${res.status}`);
          }
          await this.activeChannel!.watch();
          closeModal();
          document.dispatchEvent(new CustomEvent('mngt:channel-read', { detail: { channelId: this.activeChannel!.id } }));
          const memberPanel = this.containerTarget.querySelector<HTMLElement>('#mngt-member-list');
          if (memberPanel && !memberPanel.hidden) this.renderMemberList(memberPanel);
        })
        .catch((err: unknown) => {
          console.error('[mngt:chat] addMembers failed', err);
          btn.classList.remove('is-loading');
          btn.textContent = 'Tentar novamente';
          btn.disabled = false;
          const footer = modal.querySelector<HTMLElement>('.mngt-dm-modal-footer');
          if (footer) {
            let errEl = footer.querySelector<HTMLElement>('.mngt-add-member-error');
            if (!errEl) {
              errEl = document.createElement('span');
              errEl.className = 'mngt-add-member-error';
              errEl.style.cssText = 'color:var(--color-danger,#c92a2a);font-size:0.8rem;display:block;margin-top:4px';
              footer.appendChild(errEl);
            }
            errEl.textContent = err instanceof Error ? err.message : 'Erro ao adicionar membro';
          }
        });
    });
  }

  // ── Message search ─────────────────────────────────────────────

  private async doSearch(query: string): Promise<void> {
    if (!this.activeChannel || !this.streamClient) return;
    const resultsEl = this.containerTarget.querySelector<HTMLElement>('#mngt-search-results');
    if (!resultsEl) return;

    let messages: MessageResponse[] = [];

    // Try Stream's server-side full-text search
    try {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const result = await this.streamClient.search(
        { type: this.activeChannel.type, id: this.activeChannel.id } as any,
        query,
        { limit: 20 },
      );
      messages = ((result.results ?? []) as Array<{ message: unknown }>)
        .map((r) => r.message as MessageResponse)
        .filter((m) => !!m?.id);
    } catch (err) {
      console.warn('[mngt search] Stream API search unavailable, using local fallback:', err);
    }

    // Fallback: filter messages already loaded in channel state
    if (messages.length === 0) {
      const lower = query.toLowerCase();
      messages = (this.activeChannel.state.messages as unknown as MessageResponse[])
        .filter((m) => (m.text ?? '').toLowerCase().includes(lower))
        .slice()
        .reverse()
        .slice(0, 20);
    }

    if (messages.length === 0) {
      resultsEl.innerHTML = '<div class="mngt-search-hint">Nenhuma mensagem encontrada</div>';
      return;
    }

    resultsEl.innerHTML = messages.map((msg) => {
      const author  = (msg.user?.name as string | undefined) ?? '?';
      const rawDate = msg.created_at ? new Date(msg.created_at as string) : new Date();
      const dateStr = rawDate.toLocaleDateString('pt-BR', { day: '2-digit', month: 'short' }) +
                      ' ' + rawDate.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
      const text        = msg.text ?? '';
      const safeText    = this.escape(text.substring(0, 120));
      const highlighted = this.highlightQuery(safeText, query);
      return `<button class="mngt-search-result-item"
                      data-message-id="${this.escape(msg.id ?? '')}"
                      data-action="click->mngt--chat-panel#handleSearchResultClick">
        <div class="mngt-search-result-header">
          <span class="mngt-search-result-author">${this.escape(author)}</span>
          <span class="mngt-search-result-date">${dateStr}</span>
        </div>
        <div class="mngt-search-result-text">${highlighted}${text.length > 120 ? '…' : ''}</div>
      </button>`;
    }).join('');
  }

  private async doGlobalSearch(query: string): Promise<void> {
    if (!this.streamClient) return;
    const resultsEl = this.containerTarget.querySelector<HTMLElement>('#mngt-global-search-results');
    if (!resultsEl) return;

    interface GlobalResult { msg: MessageResponse; channelId: string; channelType: string; channelName: string }
    let results: GlobalResult[] = [];

    // Try Stream's server-side full-text search across all user channels
    try {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const response = await this.streamClient.search(
        { members: { $in: [this.currentUserId] } } as any,
        query,
        { limit: 25 },
      );
      results = ((response.results ?? []) as Array<{ message: unknown }>)
        .map((r) => {
          const msg     = r.message as MessageResponse & { cid?: string };
          if (!msg?.id || !msg.cid) return null;
          const parts      = msg.cid.split(':');
          const channelType = parts[0] ?? 'team';
          const channelId   = parts.slice(1).join(':');
          const channelName = this.channelNameMap.get(channelId) ?? channelId;
          return { msg, channelId, channelType, channelName };
        })
        .filter((r): r is GlobalResult => r !== null);
    } catch (err) {
      console.warn('[mngt global search] Stream API unavailable, using local fallback:', err);
    }

    // Fallback: search through locally loaded channel states
    if (results.length === 0) {
      const lower = query.toLowerCase();
      for (const ch of this.loadedChannels) {
        const channelId   = ch.id ?? '';
        const channelType = ch.type;
        const channelName = this.channelNameMap.get(channelId) ?? channelId;
        (ch.state.messages as unknown as MessageResponse[])
          .filter((m) => (m.text ?? '').toLowerCase().includes(lower))
          .forEach((m) => results.push({ msg: m, channelId, channelType, channelName }));
      }
      results.sort((a, b) => {
        const at = a.msg.created_at ? new Date(a.msg.created_at as string).getTime() : 0;
        const bt = b.msg.created_at ? new Date(b.msg.created_at as string).getTime() : 0;
        return bt - at;
      });
      results = results.slice(0, 20);
    }

    if (results.length === 0) {
      resultsEl.innerHTML = '<div class="mngt-search-hint">Nenhuma mensagem encontrada</div>';
      return;
    }

    resultsEl.innerHTML = results.map(({ msg, channelId, channelType, channelName }) => {
      const author  = (msg.user?.name as string | undefined) ?? '?';
      const rawDate = msg.created_at ? new Date(msg.created_at as string) : new Date();
      const dateStr = rawDate.toLocaleDateString('pt-BR', { day: '2-digit', month: 'short' }) +
                      ' ' + rawDate.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
      const text        = msg.text ?? '';
      const safeText    = this.escape(text.substring(0, 110));
      const highlighted = this.highlightQuery(safeText, query);
      const channelLabel = channelType === 'team'
        ? `<span class="mngt-search-result-channel"># ${this.escape(channelName)}</span>`
        : `<span class="mngt-search-result-channel mngt-search-result-channel--dm">@ ${this.escape(channelName)}</span>`;
      return `<button class="mngt-search-result-item"
                      data-message-id="${this.escape(msg.id ?? '')}"
                      data-channel-id="${this.escape(channelId)}"
                      data-channel-type="${this.escape(channelType)}"
                      data-channel-name="${this.escape(channelName)}">
        <div class="mngt-search-result-header">
          ${channelLabel}
          <span class="mngt-search-result-author">${this.escape(author)}</span>
          <span class="mngt-search-result-date">${dateStr}</span>
        </div>
        <div class="mngt-search-result-text">${highlighted}${text.length > 110 ? '…' : ''}</div>
      </button>`;
    }).join('');
  }

  private async jumpToMessage(messageId: string): Promise<void> {
    if (!this.activeChannel) return;
    const container = this.containerTarget.querySelector<HTMLElement>('#mngt-stream-messages');
    if (!container) return;

    const existing = container.querySelector<HTMLElement>(`[data-message-id="${messageId}"]`);
    if (existing) {
      existing.scrollIntoView({ block: 'center', behavior: 'smooth' });
      existing.classList.add('mngt-msg--highlighted');
      setTimeout(() => existing.classList.remove('mngt-msg--highlighted'), 2000);
      return;
    }

    try {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const result = await (this.activeChannel as any).query({
        messages: { limit: 25, id_around: messageId },
        members:  { limit: 0 },
        watchers: { limit: 0 },
      }) as { messages: MessageResponse[] };

      const messages = (result.messages ?? []) as MessageResponse[];
      container.innerHTML = this.renderMessageList(messages);

      this.isJumpMode = true;
      const jumpBar = this.containerTarget.querySelector<HTMLElement>('#mngt-jump-mode-bar');
      if (jumpBar) jumpBar.hidden = false;

      await new Promise<void>((resolve) => setTimeout(resolve, 50));
      const target = container.querySelector<HTMLElement>(`[data-message-id="${messageId}"]`);
      if (target) {
        target.scrollIntoView({ block: 'center', behavior: 'smooth' });
        target.classList.add('mngt-msg--highlighted');
        setTimeout(() => target.classList.remove('mngt-msg--highlighted'), 2000);
      }
    } catch { /* silent */ }
  }

  private highlightQuery(escapedText: string, query: string): string {
    if (!query) return escapedText;
    const safeQuery = this.escape(query).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    return escapedText.replace(new RegExp(`(${safeQuery})`, 'gi'), '<mark class="mngt-search-highlight">$1</mark>');
  }

  private clearSearch(): void {
    if (this.searchDebounce) { clearTimeout(this.searchDebounce); this.searchDebounce = null; }
    const resultsEl = this.containerTarget.querySelector<HTMLElement>('#mngt-search-results');
    if (resultsEl) resultsEl.innerHTML = '<div class="mngt-search-hint">Digite para buscar mensagens</div>';
    const input = this.containerTarget.querySelector<HTMLInputElement>('.mngt-search-overlay-input');
    if (input) input.value = '';
  }

  private scrollToBottom(): void {
    const el = this.containerTarget.querySelector<HTMLElement>('#mngt-stream-messages');
    if (el) el.scrollTop = el.scrollHeight;
  }

  private subscribeListUpdates(): void {
    if (!this.streamClient || this.listNotifHandler) return;
    this.listNotifHandler = () => { void this.loadChannelList(); };
    this.listAddedHandler = () => { void this.loadChannelList(); };
    this.streamClient.on('notification.message_new',      this.listNotifHandler);
    this.streamClient.on('notification.added_to_channel', this.listAddedHandler);
  }

  private unsubscribeListUpdates(): void {
    if (!this.streamClient) return;
    if (this.listNotifHandler) {
      this.streamClient.off('notification.message_new', this.listNotifHandler);
      this.listNotifHandler = null;
    }
    if (this.listAddedHandler) {
      this.streamClient.off('notification.added_to_channel', this.listAddedHandler);
      this.listAddedHandler = null;
    }
  }

  // Badge permanente no botão de toggle — independente do estado do painel/canal
  private subscribeBadgeUpdates(): void {
    if (!this.streamClient || this.notifBadgeHandler) return;
    this.notifBadgeHandler = () => { this.updateBadge(); };
    this.streamClient.on('notification.message_new', this.notifBadgeHandler);
  }

  private unsubscribeBadgeUpdates(): void {
    if (this.streamClient && this.notifBadgeHandler) {
      this.streamClient.off('notification.message_new', this.notifBadgeHandler);
      this.notifBadgeHandler = null;
    }
  }

  private updateBadge(): void {
    const panelVisible = !this.panelTarget.hidden;
    const total = this.loadedChannels.reduce((sum, ch) => {
      if (ch.id === this.activeChannel?.id) return sum;
      return sum + ch.countUnread();
    }, 0);
    this.totalUnread             = total;
    this.badgeTarget.hidden      = panelVisible || total === 0;
    this.badgeTarget.textContent = total > 99 ? '99+' : String(total);
  }

  private get companiesMapObj(): Record<string, string> {
    try {
      return JSON.parse(this.companiesMapValue || '{}') as Record<string, string>;
    } catch {
      return {};
    }
  }

  private companyNameFromChannelId(channelId: string): string {
    const slug = channelId.split('--')[0] ?? '';
    return this.companiesMapObj[slug] ?? slug;
  }

  // ── Drag-and-drop ──────────────────────────────────────────────

  handleDragOver(event: DragEvent): void {
    event.preventDefault();
    event.dataTransfer!.dropEffect = 'copy';
  }

  handleDragEnter(event: DragEvent): void {
    event.preventDefault();
    const overlay = this.containerTarget.querySelector<HTMLElement>('#mngt-drop-overlay');
    const wrap    = this.containerTarget.querySelector<HTMLElement>('#mngt-stream-form-wrap');
    if (overlay) overlay.hidden = false;
    if (wrap)    wrap.classList.add('mngt-stream-form-wrap--dragging');
  }

  handleDragLeave(event: DragEvent): void {
    const wrap = this.containerTarget.querySelector<HTMLElement>('#mngt-stream-form-wrap');
    if (!wrap) return;
    // Only hide when the cursor truly leaves the drop zone (not when entering a child)
    if (wrap.contains(event.relatedTarget as Node | null)) return;
    const overlay = this.containerTarget.querySelector<HTMLElement>('#mngt-drop-overlay');
    if (overlay) overlay.hidden = true;
    wrap.classList.remove('mngt-stream-form-wrap--dragging');
  }

  async handleDrop(event: DragEvent): Promise<void> {
    event.preventDefault();
    const overlay = this.containerTarget.querySelector<HTMLElement>('#mngt-drop-overlay');
    const wrap    = this.containerTarget.querySelector<HTMLElement>('#mngt-stream-form-wrap');
    if (overlay) overlay.hidden = true;
    if (wrap)    wrap.classList.remove('mngt-stream-form-wrap--dragging');

    const files = Array.from(event.dataTransfer?.files ?? [])
      .filter((f) => f.type.startsWith('image/'));
    if (files.length === 0) return;

    // Reuse the same file-select pipeline
    const fakeInput = { files: files as unknown as FileList };
    const fakeEvent = { target: fakeInput } as unknown as Event;
    await this.handleFileSelect(fakeEvent);
  }

  // ── Clipboard paste ────────────────────────────────────────────

  async handlePaste(event: ClipboardEvent): Promise<void> {
    const items = Array.from(event.clipboardData?.items ?? []);
    const imageFiles = items
      .filter((item) => item.kind === 'file' && item.type.startsWith('image/'))
      .map((item) => item.getAsFile())
      .filter((f): f is File => f !== null);

    if (imageFiles.length === 0) return;

    event.preventDefault();
    const fakeInput = { files: imageFiles as unknown as FileList };
    const fakeEvent = { target: fakeInput } as unknown as Event;
    await this.handleFileSelect(fakeEvent);
  }

  // ── Attach menu ────────────────────────────────────────────────

  toggleAttachMenu(event: Event): void {
    event.stopPropagation();
    const menu = this.containerTarget.querySelector<HTMLElement>('#mngt-attach-menu');
    if (!menu) return;
    const opening = menu.hidden;
    menu.hidden = !opening;
    if (!opening) return;
    const closeOnOutsideClick = (e: MouseEvent): void => {
      const btn = this.containerTarget.querySelector<HTMLElement>('.mngt-stream-attach-btn');
      if (!menu.contains(e.target as Node) && e.target !== btn) {
        menu.hidden = true;
        document.removeEventListener('click', closeOnOutsideClick);
      }
    };
    setTimeout(() => document.addEventListener('click', closeOnOutsideClick), 0);
  }

  triggerFileInput(event: Event): void {
    event.stopPropagation();
    const menu = this.containerTarget.querySelector<HTMLElement>('#mngt-attach-menu');
    if (menu) menu.hidden = true;
    this.containerTarget.querySelector<HTMLInputElement>('#mngt-stream-file-input')?.click();
  }

  // ── Image upload actions ───────────────────────────────────────

  async handleFileSelect(event: Event): Promise<void> {
    const input = event.target as HTMLInputElement;
    const files = Array.from(input.files ?? []);
    input.value = '';

    const validCount = this.pendingImages.filter((i) => !i.error).length;
    const available  = 4 - validCount;
    if (available <= 0) {
      this.showImageLimitToast('Máximo de 4 imagens por mensagem');
      return;
    }

    const toProcess = files.slice(0, available);
    if (files.length > available) {
      this.showImageLimitToast(`Apenas ${available} imagem(ns) adicionada(s) — máximo de 4`);
    }

    // Step 1 — validate magic bytes for all files in parallel (fast, local read)
    const prevalidated = await Promise.all(toProcess.map(async (file) => {
      const id         = crypto.randomUUID();
      const previewUrl = URL.createObjectURL(file);
      const valid      = await this.validateMagicBytes(file);
      return { file, id, previewUrl, valid };
    }));

    // Step 2 — push all items immediately so spinners appear before any fetch starts
    for (const { file, id, previewUrl, valid } of prevalidated) {
      if (!valid) {
        this.pendingImages.push({ id, url: '', filename: file.name, previewUrl, uploading: false,
          error: `${file.name}: tipo não permitido ou arquivo corrompido` });
      } else if (file.size > 10 * 1024 * 1024) {
        this.pendingImages.push({ id, url: '', filename: file.name, previewUrl, uploading: false,
          error: `${file.name}: excede 10 MB` });
      } else {
        this.pendingImages.push({ id, url: '', filename: file.name, previewUrl, uploading: true });
      }
    }
    this.renderPendingImages();
    this.updateSendButton();

    // Step 3 — upload valid files in parallel; update each entry in-place when done
    await Promise.all(
      prevalidated
        .filter(({ valid, file }) => valid && file.size <= 10 * 1024 * 1024)
        .map(async ({ file, id }) => {
          try {
            const form = new FormData();
            form.append('image', file);
            const resp = await fetch('/mngt/stream/images', {
              method: 'POST', body: form,
              headers: { 'X-CSRF-Token': this.csrfToken() },
            });
            if (!resp.ok) throw new Error('upload failed');
            const data = await resp.json() as { url: string; id: number };
            const entry = this.pendingImages.find((p) => p.id === id);
            if (entry) { entry.url = data.url; entry.uploading = false; }
          } catch {
            const entry = this.pendingImages.find((p) => p.id === id);
            if (entry) { entry.uploading = false; entry.error = `${file.name}: falha no upload`; }
          }
          this.renderPendingImages();
          this.updateSendButton();
        })
    );
  }

  removePendingImage(event: Event): void {
    const btn = event.currentTarget as HTMLElement;
    const imgId = btn.dataset['imgId'] ?? '';
    const img = this.pendingImages.find((i) => i.id === imgId);
    if (img) URL.revokeObjectURL(img.previewUrl);
    this.pendingImages = this.pendingImages.filter((i) => i.id !== imgId);
    this.renderPendingImages();
    this.updateSendButton();
  }

  // ── Image upload helpers ───────────────────────────────────────

  private showImageLimitToast(message: string): void {
    const wrap = this.containerTarget.querySelector<HTMLElement>('#mngt-stream-form-wrap');
    if (!wrap) return;
    const existing = wrap.querySelector<HTMLElement>('.mngt-img-limit-toast');
    if (existing) { existing.textContent = message; return; }
    const toast = document.createElement('div');
    toast.className = 'mngt-img-limit-toast';
    toast.textContent = message;
    wrap.prepend(toast);
    setTimeout(() => toast.remove(), 3000);
  }

  private async validateMagicBytes(file: File): Promise<boolean> {
    const buf   = await file.slice(0, 16).arrayBuffer();
    const bytes = new Uint8Array(buf);
    // JPEG: FF D8 FF
    if (bytes[0] === 0xFF && bytes[1] === 0xD8 && bytes[2] === 0xFF) return true;
    // PNG: 89 50 4E 47
    if (bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4E && bytes[3] === 0x47) return true;
    // GIF: 47 49 46 38
    if (bytes[0] === 0x47 && bytes[1] === 0x49 && bytes[2] === 0x46 && bytes[3] === 0x38) return true;
    // WebP: RIFF....WEBP
    if (bytes[0] === 0x52 && bytes[1] === 0x49 && bytes[2] === 0x46 && bytes[3] === 0x46 &&
        bytes[8] === 0x57 && bytes[9] === 0x45 && bytes[10] === 0x42 && bytes[11] === 0x50) return true;
    return false;
  }

  private renderPendingImages(): void {
    const area = this.containerTarget.querySelector<HTMLElement>('#mngt-stream-attachments');
    if (!area) return;

    if (this.pendingImages.length === 0) { area.innerHTML = ''; return; }

    const errorCount = this.pendingImages.filter((i) => !!i.error).length;
    area.innerHTML = this.pendingImages.map((img) => `
      <div class="mngt-attach-preview${img.error ? ' mngt-attach-preview--error' : ''}" data-img-id="${img.id}">
        ${img.error
          ? `<span class="mngt-attach-error-msg">${this.escape(img.error)}</span>`
          : `<img src="${img.previewUrl}" alt="${this.escape(img.filename)}" />
             ${img.uploading ? '<span class="mngt-attach-spinner"></span>' : ''}`
        }
        <button class="mngt-attach-remove" type="button"
                data-action="click->mngt--chat-panel#removePendingImage"
                data-img-id="${img.id}" aria-label="Remover">×</button>
      </div>`).join('') +
      (errorCount > 0
        ? `<div class="mngt-attach-error-summary">${errorCount} arquivo(s) inválido(s) — corrija antes de enviar</div>`
        : '');
  }

  private updateSendButton(): void {
    const sendBtn = this.containerTarget.querySelector<HTMLButtonElement>('.mngt-stream-send');
    if (!sendBtn) return;
    const text        = this.containerTarget.querySelector<HTMLTextAreaElement>('#mngt-stream-input')?.value.trim() ?? '';
    const hasError    = this.pendingImages.some((i) => !!i.error);
    const hasUploading = this.pendingImages.some((i) => i.uploading);
    const hasImages   = this.pendingImages.some((i) => !i.error && i.url);
    sendBtn.disabled  = (!text && !hasImages) || hasError || hasUploading;
  }

  private escape(text: string): string {
    return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  private csrfToken(): string {
    return document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')?.content ?? '';
  }

  private readonly onConnectionChanged = (event: StreamEvent): void => {
    const online = (event as unknown as Record<string, unknown>)['online'] !== false;
    const body   = this.panelTarget.querySelector('.mngt-chat-panel-body');
    if (!body) return;
    let banner = body.querySelector<HTMLElement>('#mngt-reconnect-banner');
    if (!online) {
      if (!banner) {
        banner           = document.createElement('div');
        banner.id        = 'mngt-reconnect-banner';
        banner.className = 'mngt-reconnect-banner';
        banner.textContent = 'Reconectando…';
        body.prepend(banner);
      }
      banner.hidden = false;
    } else if (banner) {
      banner.hidden = true;
      // Refresh the channel list so unread counts reflect messages missed during disconnect.
      if (!this.activeChannel) void this.loadChannelList();
    }
  };
}
