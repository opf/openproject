(() => {
  const root = document.querySelector("[data-offline-page]");
  if (!root) return;

  const MIN_RETRYING_MS = 600;
  const RELOAD_DELAY_MS = 1000;
  const BACKOFF_MS = [5000, 10000, 20000, 40000, 60000];

  const part = (name) => root.querySelector(`[data-offline-target="${name}"]`);
  const headline = part("headline");
  const button = part("button");
  const label = part("label");
  const status = part("status");
  const spinner = part("spinner");

  let busy = false;
  let timer = null;
  let attempt = 0;

  const render = (state, { text, status: statusKey }) => {
    busy = state === "retrying" || state === "online";
    root.dataset.state = state;
    headline.textContent = root.dataset[state === "online" ? "headlineOnline" : "headlineOffline"];
    label.textContent = root.dataset[text];
    status.textContent = statusKey ? root.dataset[statusKey] : "";
    spinner.hidden = !busy;
    button.setAttribute("aria-disabled", String(busy));
    button.setAttribute("aria-busy", String(busy));
  };

  const pause = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

  const scheduleRetry = () => {
    const delay = BACKOFF_MS[Math.min(attempt, BACKOFF_MS.length - 1)];
    attempt += 1;
    timer = setTimeout(retry, delay);
  };

  async function retry() {
    if (busy) return;
    clearTimeout(timer);
    render("retrying", { text: "retryingLabel", status: "statusChecking" });

    const [reachable] = await Promise.all([
      fetch(location.href, { method: "HEAD", cache: "no-store" }).then((response) => response.ok, () => false),
      pause(MIN_RETRYING_MS),
    ]);

    if (reachable) {
      render("online", { text: "reloadingLabel", status: "statusRestored" });
      await pause(RELOAD_DELAY_MS);
      location.replace(location.href);
    } else {
      render("still", { text: "retryLabel", status: "statusStill" });
      scheduleRetry();
    }
  }

  button.addEventListener("click", () => {
    if (busy) return;
    attempt = 0;
    retry();
  });
  window.addEventListener("online", retry);

  render("offline", { text: "retryLabel" });
  scheduleRetry();
})();
