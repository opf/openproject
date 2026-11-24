// Generated from packages/service-worker; do not edit by hand. Rebuild with `npm run build` in that folder.
"use strict";
(() => {
  // src/config.ts
  if (!globalThis.OP_SW) {
    throw new Error("Service worker configuration is missing: OP_SW was not set before the bundle was imported.");
  }
  var Config = Object.freeze(globalThis.OP_SW);

  // src/sw-global.ts
  var sw = self;

  // src/notification-click.ts
  var NotificationClick = class _NotificationClick {
    static sameOriginUrl(url) {
      const resolved = new URL(url, sw.location.href);
      return resolved.origin === sw.location.origin ? resolved.href : new URL(Config.urls.home, sw.location.href).href;
    }
    static async windowsInScope() {
      const windows = await sw.clients.matchAll({ type: "window" });
      return windows.filter((candidate) => candidate.url.startsWith(sw.registration.scope));
    }
    static async open(requestedUrl) {
      const url = _NotificationClick.sameOriginUrl(requestedUrl);
      const clients = await _NotificationClick.windowsInScope();
      const client = clients.find((candidate) => candidate.visibilityState === "visible" || candidate.focused) ?? clients[0];
      if (!client) return sw.clients.openWindow(url);
      try {
        await client.focus();
        await client.navigate(url);
      } catch {
        return sw.clients.openWindow(url);
      }
      return void 0;
    }
  };

  // src/offline-page.ts
  var OfflinePage = class _OfflinePage {
    static async precache() {
      const response = await fetch(new Request(Config.urls.offline, { credentials: "omit", cache: "reload" }));
      if (!response.ok || response.redirected) throw new Error("Offline page unavailable");
      const cache = await caches.open(Config.cache.name);
      await cache.put(Config.urls.offline, response);
    }
    static async deleteStaleCaches() {
      for (const name of await caches.keys()) {
        if (name.startsWith(Config.cache.prefix) && name !== Config.cache.name && name !== Config.cache.state) await caches.delete(name);
      }
    }
    static respondTo(event) {
      const { request } = event;
      if (request.mode !== "navigate" || request.destination !== "document" || request.method !== "GET") return void 0;
      const response = _OfflinePage.load(event);
      event.respondWith(response);
      return response;
    }
    static async load(event) {
      let preloaded;
      try {
        preloaded = await event.preloadResponse;
      } catch {
        preloaded = void 0;
      }
      try {
        return preloaded ?? await fetch(event.request);
      } catch {
        const cache = await caches.open(Config.cache.name);
        return await cache.match(Config.urls.offline) ?? Response.error();
      }
    }
  };

  // src/badge.ts
  var badgeNavigator = navigator;
  var Badge = class {
    static set(count) {
      return badgeNavigator.setAppBadge?.(count).catch(() => void 0);
    }
    static clear() {
      return badgeNavigator.clearAppBadge?.().catch(() => void 0);
    }
  };

  // src/constants.ts
  var Tags = {
    prefix: "openproject-",
    workPackage: /^openproject-(\d+)-wp-/,
    placeholder: "openproject-unread",
    nothingNew: "openproject-nothing-new",
    more: "openproject-more"
  };
  var FETCH_TIMEOUT_MS = 1e4;
  var SIGN_OUT_TIMEOUT_MS = 1e4;
  var RECONCILE_MIN_INTERVAL_MS = 1e4;
  var MAX_REMEMBERED_UNLISTED = 50;

  // src/notification-fingerprint.ts
  var NotificationFingerprint = class _NotificationFingerprint {
    static async of(...parts) {
      const bytes = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(JSON.stringify(parts)));
      return Array.from(new Uint8Array(bytes), (byte) => byte.toString(16).padStart(2, "0")).join("");
    }
    static async addTo({ groups, more }) {
      return {
        groups: await Promise.all(groups.map(async (group) => ({
          ...group,
          fingerprint: await _NotificationFingerprint.of(group.revision, group.title, group.body ?? "")
        }))),
        more: more && { ...more, fingerprint: await _NotificationFingerprint.of(more.title) }
      };
    }
  };

  // src/notification-rules.ts
  var NotificationRules = class _NotificationRules {
    static activityAt(group) {
      return Number(group.revision.split(":")[1]) || 0;
    }
    static pruneUnlisted({ state, groups }) {
      const listedTags = /* @__PURE__ */ new Set([...groups.map((group) => group.tag), Tags.more]);
      const entries = Object.entries(state);
      const unlisted = entries.filter(([tag]) => !listedTags.has(tag)).sort(([, a], [, b]) => (b.at ?? 0) - (a.at ?? 0)).slice(0, MAX_REMEMBERED_UNLISTED);
      return Object.fromEntries([...entries.filter(([tag]) => listedTags.has(tag)), ...unlisted]);
    }
    static staleTags({ groups, more, openTags }) {
      const keepTags = new Set(groups.map((group) => group.tag));
      if (more) keepTags.add(Tags.more);
      return openTags.filter((tag) => !keepTags.has(tag));
    }
    static isNewActivity(previous, at) {
      return previous?.at === void 0 || at > previous.at;
    }
    static needsRefresh({ group, previous, openTags }) {
      const onlyPlaceholderOpen = openTags.length > 0 && openTags.every((tag) => tag === Tags.placeholder);
      return onlyPlaceholderOpen || !!previous?.evicted || openTags.includes(group.tag) && previous?.fingerprint !== group.fingerprint;
    }
    static evictedState(closeTags, state) {
      const evicted = {};
      closeTags.filter((tag) => state[tag]?.at !== void 0).forEach((tag) => {
        evicted[tag] = { ...state[tag], evicted: true };
      });
      return evicted;
    }
    static stateAfterClose({ closeTags, groups, more, state }) {
      const remaining = Object.fromEntries(Object.entries(state).filter(([tag]) => !closeTags.includes(tag)));
      if (!more) return remaining;
      return _NotificationRules.pruneUnlisted({
        state: { ...remaining, ..._NotificationRules.evictedState(closeTags, state) },
        groups
      });
    }
    static decide({ groups, more, openTags, state }) {
      const closeTags = _NotificationRules.staleTags({ groups, more, openTags });
      const nextState = {};
      const show = [];
      if (more) {
        Object.assign(nextState, _NotificationRules.evictedState(closeTags, state));
        nextState[Tags.more] = { fingerprint: more.fingerprint };
        if (state[Tags.more]?.fingerprint !== more.fingerprint || !openTags.includes(Tags.more)) {
          show.push({ kind: "more", more });
        }
      }
      for (const group of [...groups].reverse()) {
        const previous = state[group.tag];
        const at = _NotificationRules.activityAt(group);
        nextState[group.tag] = { fingerprint: group.fingerprint, at: Math.max(at, previous?.at ?? 0) };
        if (_NotificationRules.isNewActivity(previous, at)) {
          show.push({ kind: "alert", group });
        } else if (_NotificationRules.needsRefresh({ group, previous, openTags })) {
          show.push({ kind: "refresh", group });
        }
      }
      if (show.length === 0) {
        show.push(openTags.includes(groups[0].tag) ? { kind: "refresh", group: groups[0] } : { kind: "nothingNew" });
      }
      const nextRemembered = more ? _NotificationRules.pruneUnlisted({ state: { ...state, ...nextState }, groups }) : nextState;
      return { show, state: nextRemembered };
    }
  };

  // src/notifications.ts
  var Notifications = class _Notifications {
    static async listOpen() {
      const notifications = await sw.registration.getNotifications();
      return notifications.filter((notification) => notification.tag.startsWith(Tags.prefix));
    }
    static ownerOf(tag) {
      return Tags.workPackage.exec(tag)?.[1];
    }
    static close(open, tags) {
      open.filter((notification) => tags.includes(notification.tag)).forEach((notification) => notification.close());
    }
    static closeAll(open) {
      open.forEach((notification) => notification.close());
    }
    static show(item) {
      switch (item.kind) {
        case "alert":
          return _Notifications.showGroup(item.group, { renotify: true });
        case "refresh":
          return _Notifications.showGroup(item.group, { silent: true, renotify: false });
        case "more":
          return _Notifications.showMore(item.more);
        case "nothingNew":
          return _Notifications.showFallback(Tags.nothingNew);
        default:
          return _Notifications.showFallback();
      }
    }
    static showGroup(group, flags) {
      return _Notifications.display(group.title, {
        tag: group.tag,
        body: group.body,
        data: { url: group.url, revision: group.revision },
        ...flags
      });
    }
    static showMore(more) {
      return _Notifications.display(more.title, {
        tag: Tags.more,
        silent: true,
        data: { url: more.url, revision: more.title }
      });
    }
    static showFallback(tag = Tags.placeholder) {
      return _Notifications.display(Config.push.fallbackTitle, {
        tag,
        silent: true,
        renotify: false,
        data: { url: Config.urls.home, revision: "fallback" }
      });
    }
    static showAllRead() {
      return _Notifications.display(Config.push.allReadTitle, {
        tag: Tags.placeholder,
        silent: true,
        data: { url: Config.urls.home, revision: "all-read" }
      });
    }
    static display(title, options) {
      return sw.registration.showNotification(title, { icon: Config.push.icon, ...options });
    }
  };

  // src/push-state.ts
  var PushState = class _PushState {
    static get shownUrl() {
      return `${Config.urls.push}?shown`;
    }
    static async read() {
      const cache = await caches.open(Config.cache.state);
      const stored = await cache.match(_PushState.shownUrl);
      return stored ? stored.json() : {};
    }
    static async write(state) {
      const cache = await caches.open(Config.cache.state);
      await cache.put(_PushState.shownUrl, new Response(JSON.stringify(state), { headers: { "Content-Type": "application/json" } }));
    }
    static clear() {
      return _PushState.write({});
    }
  };

  // src/unread-summary.ts
  var UnreadSummary = class {
    static async fetch() {
      try {
        const response = await fetch(Config.urls.push, {
          credentials: "include",
          cache: "no-store",
          headers: { Accept: "application/json" },
          signal: AbortSignal.timeout(FETCH_TIMEOUT_MS)
        });
        if (response.status === 401 || response.status === 403) return { outcome: "signedOut" };
        if (!response.ok) return { outcome: "unavailable" };
        const data = await response.json();
        if (!data) return { outcome: "unavailable" };
        if (data.count === 0) return { outcome: "empty" };
        return { outcome: "unread", count: data.count, groups: data.groups, more: data.more };
      } catch {
        return { outcome: "unavailable" };
      }
    }
  };

  // src/push-handler.ts
  var PushHandler = class _PushHandler {
    queue = Promise.resolve();
    pendingReconcile;
    lastReconcileStartedAt = -Infinity;
    signOutGeneration = 0;
    signOutsInProgress = 0;
    accountId;
    signOutPath;
    constructor() {
      this.signOutPath = new URL(Config.urls.signOut, sw.location.href).pathname;
    }
    isSignOut(request) {
      return new URL(request.url).pathname === this.signOutPath;
    }
    static async settled(navigation) {
      let timer;
      try {
        await Promise.race([
          navigation.catch(() => void 0),
          new Promise((resolve) => {
            timer = setTimeout(resolve, SIGN_OUT_TIMEOUT_MS);
          })
        ]);
      } finally {
        clearTimeout(timer);
      }
    }
    signOut(navigation) {
      this.signOutGeneration += 1;
      this.signOutsInProgress += 1;
      const cleared = this.clearForSignOut().catch(() => void 0);
      const clearedAfterSettled = _PushHandler.settled(navigation).then(() => {
        this.signOutGeneration += 1;
        this.signOutsInProgress -= 1;
        return this.enqueue(() => this.clearForSignOut());
      });
      return Promise.all([cleared, clearedAfterSettled]);
    }
    onPush(event) {
      event.waitUntil(this.enqueue(() => this.showUnread()));
    }
    onMessage(event) {
      const { type, userId } = event.data ?? {};
      if (type === "reconcile") {
        event.waitUntil(this.requestReconcile());
      } else if (type === "account" && userId) {
        event.waitUntil(this.switchAccount(String(userId)));
      }
    }
    requestReconcile() {
      if (this.pendingReconcile) return this.pendingReconcile;
      const delay = this.lastReconcileStartedAt + RECONCILE_MIN_INTERVAL_MS - Date.now();
      this.pendingReconcile = new Promise((resolve) => setTimeout(resolve, Math.max(0, delay))).then(
        () => this.enqueue(() => {
          this.pendingReconcile = void 0;
          this.lastReconcileStartedAt = Date.now();
          return this.reconcile();
        })
      );
      return this.pendingReconcile;
    }
    switchAccount(userId) {
      const changed = this.accountId !== void 0 && this.accountId !== userId;
      if (changed) this.signOutGeneration += 1;
      this.accountId = userId;
      return this.enqueue(async () => {
        const closed = await this.closeOtherAccounts(userId, changed);
        if (changed || closed) await this.refreshBadge();
      });
    }
    enqueue(task) {
      this.queue = this.queue.then(task, task).catch(() => void 0);
      return this.queue;
    }
    // A push that shows no notification makes Chrome show a generic one, so every path ends in showNotification.
    async showUnread() {
      try {
        await this.render();
      } catch {
        await Notifications.showFallback();
      }
    }
    async render() {
      const generation = this.signOutGeneration;
      const summary = await UnreadSummary.fetch();
      if (generation !== this.signOutGeneration || this.signOutsInProgress > 0) return Notifications.showFallback();
      switch (summary.outcome) {
        case "signedOut":
          await Badge.clear();
          await this.closeAndForgetAll();
          return Notifications.showFallback();
        case "unavailable":
          return Notifications.showFallback();
        case "empty":
          await this.closeAndForgetAll();
          await Notifications.showAllRead();
          return Badge.clear();
        default:
          await Badge.set(summary.count);
          return this.showUnreadGroups(summary);
      }
    }
    async reconcile() {
      const generation = this.signOutGeneration;
      if ((await Notifications.listOpen()).length === 0) return this.refreshBadge();
      const summary = await UnreadSummary.fetch();
      if (generation !== this.signOutGeneration || this.signOutsInProgress > 0) return;
      switch (summary.outcome) {
        case "signedOut":
        case "empty":
          await this.closeAndForgetAll();
          return Badge.clear();
        case "unavailable":
          return;
        default:
          await Badge.set(summary.count);
          return this.closeUnlisted(summary);
      }
    }
    async refreshBadge() {
      const generation = this.signOutGeneration;
      const summary = await UnreadSummary.fetch();
      if (generation !== this.signOutGeneration || this.signOutsInProgress > 0) return;
      if (summary.outcome === "unavailable") return;
      return summary.outcome === "unread" ? Badge.set(summary.count) : Badge.clear();
    }
    async closeStale({ groups, more }) {
      const state = await PushState.read();
      const open = await Notifications.listOpen();
      const openTags = open.map((notification) => notification.tag);
      const closeTags = NotificationRules.staleTags({ groups, more, openTags });
      Notifications.close(open, closeTags);
      return { state, openTags, closeTags };
    }
    async closeUnlisted(summary) {
      const { state, closeTags } = await this.closeStale(summary);
      if (closeTags.length === 0) return;
      await PushState.write(NotificationRules.stateAfterClose({ closeTags, groups: summary.groups, more: summary.more, state }));
    }
    async showUnreadGroups(summary) {
      const { groups, more } = summary;
      const { state, openTags } = await this.closeStale(summary);
      if (groups.length === 0) return Notifications.showFallback();
      const decision = NotificationRules.decide({ ...await NotificationFingerprint.addTo({ groups, more }), openTags, state });
      for (const item of decision.show) await Notifications.show(item);
      await PushState.write(decision.state);
    }
    async closeAndForgetAll() {
      Notifications.closeAll(await Notifications.listOpen());
      await PushState.clear();
    }
    async closeOtherAccounts(userId, changed) {
      const isOther = (tag) => {
        const owner = Notifications.ownerOf(tag);
        return owner === void 0 ? changed : owner !== userId;
      };
      const open = await Notifications.listOpen();
      const closeTags = open.map((notification) => notification.tag).filter(isOther);
      Notifications.close(open, closeTags);
      const state = await PushState.read();
      const remembered = Object.entries(state).filter(([tag]) => !isOther(tag));
      const forgot = remembered.length !== Object.keys(state).length;
      if (forgot) await PushState.write(Object.fromEntries(remembered));
      return closeTags.length > 0 || forgot;
    }
    async clearForSignOut() {
      await this.closeAndForgetAll();
      await Badge.clear();
    }
  };

  // src/main.ts
  var pushHandler = new PushHandler();
  sw.addEventListener("install", (event) => {
    event.waitUntil(
      OfflinePage.precache().catch((error) => {
        console.warn("Offline page could not be precached", error);
        throw error;
      }).then(() => sw.skipWaiting())
    );
  });
  sw.addEventListener("activate", (event) => {
    event.waitUntil(
      OfflinePage.deleteStaleCaches().then(() => sw.registration.navigationPreload?.enable()).then(() => sw.clients.claim())
    );
  });
  sw.addEventListener("fetch", (event) => {
    const response = OfflinePage.respondTo(event);
    if (response && pushHandler.isSignOut(event.request)) {
      event.waitUntil(pushHandler.signOut(response));
    }
  });
  sw.addEventListener("push", (event) => pushHandler.onPush(event));
  sw.addEventListener("message", (event) => pushHandler.onMessage(event));
  sw.addEventListener("notificationclick", (event) => {
    event.notification.close();
    const requestedUrl = event.notification.data?.url;
    event.waitUntil(NotificationClick.open(requestedUrl?.length ? requestedUrl : Config.urls.home));
  });
})();
