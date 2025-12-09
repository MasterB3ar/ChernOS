/* ChernOS v2.0.0 – Reactor Shell main.js */

/* ------------------ Internal state ------------------ */

const state = {
  ui: {
    activeApp: "core",
    night: false,
    audioEnabled: true,
  },
  reactor: {
    temp: 42,
    output: 61,
    pressure: 31,
    status: "NOMINAL", // NOMINAL, STRESSED, CRITICAL
    safeguards: {
      shieldX: 100,
      flowA: 100,
    },
  },
  network: {
    nodes: [
      { id: "CORE-1", status: "ONLINE", load: 0.61 },
      { id: "FLOW-A", status: "ONLINE", load: 0.34 },
      { id: "SHIELD-X", status: "ONLINE", load: 0.22 },
      { id: "DIAG-NET", status: "ONLINE", load: 0.18 },
      { id: "OPS-TOWER", status: "ONLINE", load: 0.42 },
    ],
    packetSeq: 0,
  },
  containment: {
    mode: "SEALED", // SEALED, STRESSED, BREACHED
    coolantRoute: "balance", // loop-a, loop-b, balance
    faults: [],
  },
  audio: {
    master: 0.8,
    music: 0.6,
    sfx: 0.9,
    currentTrack: "normal", // normal, stress, meltdown
  },
  logs: [],
  persist: {
    enabled: false,
  },
};

/* ------------------ Internal message bus ------------------ */

const bus = {
  listeners: {},
  on(event, handler) {
    if (!this.listeners[event]) this.listeners[event] = [];
    this.listeners[event].push(handler);
  },
  emit(event, payload) {
    (this.listeners[event] || []).forEach((fn) => {
      try {
        fn(payload);
      } catch (e) {
        console.error("Handler error for event", event, e);
      }
    });
  },
};

/* ------------------ Plugin system ------------------ */

const plugins = [];

function registerPlugin(plugin) {
  plugins.push(plugin);
  if (typeof plugin.init === "function") {
    plugin.init({ state, bus, log });
  }
}

/* ------------------ DOM helpers ------------------ */

function qs(sel) {
  return document.querySelector(sel);
}

function qsa(sel) {
  return Array.from(document.querySelectorAll(sel));
}

/* ------------------ Logging & persistence ------------------ */

function log(line) {
  const ts = new Date();
  const stamp = ts.toISOString().replace("T", " ").split(".")[0];
  const msg = `[${stamp}] ${line}`;
  state.logs.push(msg);
  const el = qs("#log-output");
  if (el) {
    el.textContent += msg + "\n";
    el.scrollTop = el.scrollHeight;
  }
  const consoleOut = qs("#console-output");
  if (consoleOut) {
    consoleOut.textContent += msg + "\n";
    consoleOut.scrollTop = consoleOut.scrollHeight;
  }
  try {
    localStorage.setItem("chernos_logs", JSON.stringify(state.logs.slice(-500)));
  } catch {}
}

function loadPersistedState() {
  try {
    const raw = localStorage.getItem("chernos_state_v3");
    if (raw) {
      const saved = JSON.parse(raw);
      Object.assign(state.ui, saved.ui || {});
      Object.assign(state.audio, saved.audio || {});
      log("RESTORE: loaded persisted UI/audio state.");
      state.persist.enabled = true;
    }
  } catch {
    log("PERSIST: failed to parse saved state.");
  }
}

function savePersistedState() {
  const snapshot = {
    ui: state.ui,
    audio: state.audio,
  };
  try {
    localStorage.setItem("chernos_state_v3", JSON.stringify(snapshot));
  } catch {
    // ignore
  }
}

/* ------------------ Clock / topbar ------------------ */

function updateClock() {
  const el = qs("#bc-clock");
  if (!el) return;
  const now = new Date();
  const timeStr = now.toLocaleTimeString("en-GB", {
    hour12: false,
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  });
  const dateStr = now.toLocaleDateString("en-GB");
  el.textContent = `${timeStr} ${dateStr}`;
}

/* ------------------ UI: app switching / night mode ------------------ */

function setActiveApp(appId) {
  state.ui.activeApp = appId;
  qsa(".bc-window").forEach((w) => {
    w.classList.toggle("bc-window-active", w.dataset.appWindow === appId);
  });
  log(`UI: switched to app ${appId}.`);
}

function toggleNightMode() {
  state.ui.night = !state.ui.night;
  const root = document.body;
  root.classList.toggle("bc-night", state.ui.night);
  log(`UI: night shift ${state.ui.night ? "enabled" : "disabled"}.`);
}

/* ------------------ Audio system ------------------ */

const audioHandles = {};

function initAudio() {
  audioHandles.tracks = {
    normal: qs("#track-normal"),
    stress: qs("#track-stress"),
    meltdown: qs("#track-meltdown"),
  };
  audioHandles.sfx = {
    click: qs("#sfx-click"),
    lever: qs("#sfx-lever"),
    alarm: qs("#sfx-alarm"),
    startup: qs("#sfx-startup"),
  };

  setAudioVolumes();
  // Play startup chime
  if (audioHandles.sfx.startup) {
    tryPlay(audioHandles.sfx.startup);
  }
  log("AUDIO: initialized.");
}

function setAudioVolumes() {
  const { master, music, sfx } = state.audio;
  const musicVol = master * music;
  const sfxVol = master * sfx;
  if (audioHandles.tracks) {
    Object.values(audioHandles.tracks).forEach((a) => {
      if (a) a.volume = musicVol;
    });
  }
  if (audioHandles.sfx) {
    Object.values(audioHandles.sfx).forEach((a) => {
      if (a) a.volume = sfxVol;
    });
  }
}

function tryPlay(el) {
  if (!el || !state.ui.audioEnabled) return;
  el.currentTime = 0;
  el.play().catch(() => {});
}

function setMusicTrack(trackId) {
  if (!audioHandles.tracks) return;
  state.audio.currentTrack = trackId;
  Object.entries(audioHandles.tracks).forEach(([id, el]) => {
    if (!el) return;
    if (id === trackId) {
      el.loop = true;
      el.play().catch(() => {});
    } else {
      el.pause();
    }
  });
  log(`AUDIO: set music track ${trackId}.`);
}

/* Audio command handler: audio test <id> */

function handleAudioTest(id) {
  const lower = (id || "").toLowerCase();
  if (lower === "alarm" && audioHandles.sfx.alarm) {
    tryPlay(audioHandles.sfx.alarm);
    log("AUDIO TEST: alarm.");
  } else if (lower === "startup" && audioHandles.sfx.startup) {
    tryPlay(audioHandles.sfx.startup);
    log("AUDIO TEST: startup.");
  } else if (audioHandles.sfx[lower]) {
    tryPlay(audioHandles.sfx[lower]);
    log(`AUDIO TEST: ${lower}.`);
  } else {
    log(`AUDIO TEST: unknown id '${id}'.`);
  }
}

/* ------------------ Reactor simulation ------------------ */

function updateReactorUI() {
  // Temperature rings
  const tEl = qs("#ring-temp-value");
  const oEl = qs("#ring-output-value");
  const pEl = qs("#ring-pressure-value");
  if (tEl) tEl.textContent = `${Math.round(state.reactor.temp)}%`;
  if (oEl) oEl.textContent = `${Math.round(state.reactor.output)}%`;
  if (pEl) pEl.textContent = `${Math.round(state.reactor.pressure)}%`;

  // Status chips
  const coreChip = qs("#status-core-text");
  if (coreChip) coreChip.textContent = state.reactor.status;

  // Safeguards
  const sShield = qs("#shield-x-level");
  const sFlow = qs("#flow-a-level");
  if (sShield) sShield.textContent = `${Math.round(state.reactor.safeguards.shieldX)}%`;
  if (sFlow) sFlow.textContent = `${Math.round(state.reactor.safeguards.flowA)}%`;
}

function reactorTick() {
  // Simple drift
  state.reactor.temp += (Math.random() - 0.5) * 2;
  state.reactor.output += (Math.random() - 0.5) * 1.5;
  state.reactor.pressure += (Math.random() - 0.5) * 1.2;

  // Clamp
  state.reactor.temp = Math.max(0, Math.min(120, state.reactor.temp));
  state.reactor.output = Math.max(0, Math.min(120, state.reactor.output));
  state.reactor.pressure = Math.max(0, Math.min(120, state.reactor.pressure));

  // Status level
  const temp = state.reactor.temp;
  let status = "NOMINAL";
  if (temp > 80 || state.reactor.pressure > 80) status = "STRESSED";
  if (temp > 100 || state.reactor.pressure > 100) status = "CRITICAL";
  if (status !== state.reactor.status) {
    state.reactor.status = status;
    bus.emit("reactor-status-changed", status);
  }

  updateReactorUI();
}

/* Levers */

function attachLeverHandlers() {
  qsa(".bc-lever").forEach((btn) => {
    btn.addEventListener("click", () => {
      const kind = btn.dataset.lever;
      if (audioHandles.sfx.lever) tryPlay(audioHandles.sfx.lever);

      if (kind === "power-up") {
        state.reactor.output += 5;
        state.reactor.temp += 3;
        log("REACTOR: power up lever.");
      } else if (kind === "power-down") {
        state.reactor.output -= 5;
        state.reactor.temp -= 2;
        log("REACTOR: power down lever.");
      } else if (kind === "scram") {
        state.reactor.output = 5;
        state.reactor.temp -= 15;
        state.reactor.pressure -= 10;
        state.reactor.safeguards.shieldX -= 10;
        log("REACTOR: SCRAM triggered.");
        bus.emit("reactor-scram", {});
      }

      reactorTick();
    });
  });
}

/* Flicker board */

const coreBoardLines = [
  "CORE LOOP A",
  "CORE LOOP B",
  "PRESSURE GRID",
  "COOLANT FEED",
  "PUMP ARRAY",
  "RAD MONITOR",
];

function updateCoreStatusBoard() {
  const ul = qs("#core-status-board");
  if (!ul) return;
  ul.innerHTML = "";
  coreBoardLines.forEach((label) => {
    const li = document.createElement("li");
    const labSpan = document.createElement("span");
    labSpan.className = "bc-status-label";
    labSpan.textContent = label;

    const valSpan = document.createElement("span");
    const r = Math.random();
    if (r < 0.7) {
      valSpan.className = "bc-status-value-ok";
      valSpan.textContent = "OK";
    } else if (r < 0.9) {
      valSpan.className = "bc-status-value-warn";
      valSpan.textContent = "WARN";
    } else {
      valSpan.className = "bc-status-value-bad";
      valSpan.textContent = "FAULT";
    }

    li.appendChild(labSpan);
    li.appendChild(valSpan);
    ul.appendChild(li);
  });
}

/* ------------------ Network simulation ------------------ */

function networkTick() {
  // Small load changes
  state.network.nodes.forEach((n) => {
    n.load += (Math.random() - 0.5) * 0.05;
    n.load = Math.max(0.05, Math.min(0.98, n.load));
  });

  updateNetworkUI();
  emitPacket();
}

function updateNetworkUI() {
  const list = qs("#network-nodes");
  if (!list) return;

  list.innerHTML = "";
  state.network.nodes.forEach((n) => {
    const li = document.createElement("li");
    const pct = Math.round(n.load * 100);
    li.textContent = `${n.id}  ::  ${n.status}  ::  LOAD ${pct}%`;
    list.appendChild(li);
  });

  const netChip = qs("#status-net-text");
  if (netChip) {
    const maxLoad = Math.max(...state.network.nodes.map((n) => n.load));
    netChip.textContent = maxLoad > 0.8 ? "BURST" : "STABLE";
  }
}

function emitPacket() {
  const stream = qs("#packet-stream");
  if (!stream) return;
  const srcIdx = Math.floor(Math.random() * state.network.nodes.length);
  let dstIdx = Math.floor(Math.random() * state.network.nodes.length);
  if (dstIdx === srcIdx) dstIdx = (dstIdx + 1) % state.network.nodes.length;
  const src = state.network.nodes[srcIdx];
  const dst = state.network.nodes[dstIdx];

  const seq = ++state.network.packetSeq;
  const latency = 2 + Math.round(Math.random() * 12);
  const line = `[#${seq.toString().padStart(5, "0")}] ${src.id} → ${dst.id}  ${latency}ms`;

  const div = document.createElement("div");
  div.textContent = line;
  stream.appendChild(div);
  while (stream.childNodes.length > 150) {
    stream.removeChild(stream.firstChild);
  }
  stream.scrollTop = stream.scrollHeight;
}

/* ------------------ Containment / faults ------------------ */

function containmentTick() {
  // Very simple model: stressed if temp high
  const temp = state.reactor.temp;
  let mode = "SEALED";
  if (temp > 80) mode = "STRESSED";
  if (temp > 105) mode = "BREACHED";

  if (mode !== state.containment.mode) {
    state.containment.mode = mode;
    bus.emit("containment-mode-changed", mode);
  }

  updateContainmentUI();
}

function updateContainmentUI() {
  const vis = qs("#containment-visual");
  if (!vis) return;
  vis.classList.remove("bc-containment-stressed", "bc-containment-breached");
  if (state.containment.mode === "STRESSED") {
    vis.classList.add("bc-containment-stressed");
  } else if (state.containment.mode === "BREACHED") {
    vis.classList.add("bc-containment-breached");
  }

  const contChip = qs("#status-containment-text");
  if (contChip) contChip.textContent = state.containment.mode;

  const faultsUl = qs("#containment-faults");
  if (faultsUl) {
    faultsUl.innerHTML = "";
    state.containment.faults.slice(-10).forEach((f) => {
      const li = document.createElement("li");
      li.textContent = f;
      faultsUl.appendChild(li);
    });
  }

  const coolantUl = qs("#coolant-status");
  if (coolantUl) {
    coolantUl.innerHTML = "";
    const li = document.createElement("li");
    li.textContent = `Coolant routing: ${state.containment.coolantRoute.toUpperCase()}`;
    coolantUl.appendChild(li);
  }
}

function pushFault(kind) {
  const stamp = new Date().toLocaleTimeString("en-GB", { hour12: false });
  const line = `${stamp}  FAULT: ${kind}`;
  state.containment.faults.push(line);
  log(line);
  bus.emit("fault-raised", kind);
}

/* simulate <fault> */

function handleSimulateFault(kind) {
  const key = (kind || "").toLowerCase();
  if (["pump", "pump-fail"].includes(key)) {
    pushFault("PUMP ARRAY FAILURE");
  } else if (["sensor", "sensor-glitch"].includes(key)) {
    pushFault("SENSOR ARRAY GLITCH");
  } else if (["pressure"].includes(key)) {
    pushFault("PRESSURE SPIKE IN LOOP B");
  } else if (["ghost", "ghost-rad", "rad"].includes(key)) {
    pushFault("GHOST RADIATION ANOMALY");
  } else if (["breach", "containment"].includes(key)) {
    pushFault("CONTAINMENT BREACH PROTOCOL");
    state.containment.mode = "BREACHED";
  } else {
    pushFault(`UNCLASSIFIED FAULT '${kind}'`);
  }
  updateContainmentUI();
}

/* Manual coolant routing buttons */

function attachCoolantHandlers() {
  qsa(".bc-routing-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      const route = btn.dataset.route;
      state.containment.coolantRoute = route;
      log(`COOLANT: routing set to ${route.toUpperCase()}.`);
      updateContainmentUI();
    });
  });
}

/* ------------------ Console (commands) ------------------ */

function handleConsoleCommand(line) {
  const trimmed = line.trim();
  if (!trimmed) return;
  log(`CONSOLE> ${trimmed}`);

  const parts = trimmed.split(/\s+/);
  const cmd = parts[0].toLowerCase();
  const rest = parts.slice(1);

  if (cmd === "audio" && rest[0] === "test") {
    handleAudioTest(rest[1] || "");
  } else if (cmd === "simulate") {
    handleSimulateFault(rest[0] || "");
  } else if (cmd === "net" && rest[0] === "status") {
    state.network.nodes.forEach((n) => {
      log(`NET STATUS: ${n.id} :: ${n.status} :: LOAD ${(n.load * 100).toFixed(1)}%`);
    });
  } else if (cmd === "net" && rest[0] === "scan") {
    log("NET SCAN: scanning fabric ...");
    setTimeout(() => log("NET SCAN: 5 nodes responsive, 0 anomalies."), 400);
  } else if (cmd === "net" && rest[0] === "trace") {
    log("NET TRACE: CORE-1 → OPS-TOWER path: CORE-1 → DIAG-NET → OPS-TOWER");
  } else if (cmd === "net" && rest[0] === "throttle") {
    log(`NET THROTTLE: limiting traffic on ${rest[1] || "FLOW-A"}.`);
  } else if (cmd === "help") {
    log("HELP: commands: audio test <id>, simulate <fault>, net status, net scan, net trace, net throttle <node>.");
  } else {
    log(`UNKNOWN COMMAND: ${cmd}`);
  }
}

/* ------------------ Hotkeys ------------------ */

function attachHotkeys() {
  document.addEventListener("keydown", (ev) => {
    if (ev.target && ev.target.id === "console-input") return;

    if (ev.altKey && !ev.shiftKey && !ev.ctrlKey) {
      if (ev.key === "1") setActiveApp("core");
      else if (ev.key === "2") setActiveApp("network");
      else if (ev.key === "3") setActiveApp("containment");
      else if (ev.key === "4") setActiveApp("logs");
      else if (ev.key === "5") setActiveApp("console");
      else if (ev.key === "6") setActiveApp("settings");
    }

    if (ev.key === "F9") {
      toggleNightMode();
    }
  });
}

/* ------------------ Initialization ------------------ */

function attachTaskbarHandlers() {
  qsa(".bc-task-btn").forEach((btn) => {
    btn.addEventListener("click", () => {
      const app = btn.dataset.app;
      setActiveApp(app);
      if (audioHandles.sfx.click) tryPlay(audioHandles.sfx.click);
    });
  });
}

function attachTopbarButtons() {
  const nightBtn = qs("#btn-night");
  const muteBtn = qs("#btn-mute");
  if (nightBtn) {
    nightBtn.addEventListener("click", () => {
      toggleNightMode();
    });
  }
  if (muteBtn) {
    muteBtn.addEventListener("click", () => {
      state.ui.audioEnabled = !state.ui.audioEnabled;
      log(`AUDIO: ${state.ui.audioEnabled ? "unmuted" : "muted"}.`);
    });
  }
}

function attachConsoleInput() {
  const input = qs("#console-input");
  if (!input) return;
  input.addEventListener("keydown", (ev) => {
    if (ev.key === "Enter") {
      const val = input.value;
      input.value = "";
      handleConsoleCommand(val);
    }
  });
}

function attachSettingsHandlers() {
  const m = qs("#volume-master");
  const mu = qs("#volume-music");
  const s = qs("#volume-sfx");
  const dumpBtn = qs("#btn-persist-dump");

  if (m) {
    m.value = state.audio.master;
    m.addEventListener("input", () => {
      state.audio.master = parseFloat(m.value);
      setAudioVolumes();
      savePersistedState();
    });
  }
  if (mu) {
    mu.value = state.audio.music;
    mu.addEventListener("input", () => {
      state.audio.music = parseFloat(mu.value);
      setAudioVolumes();
      savePersistedState();
    });
  }
  if (s) {
    s.value = state.audio.sfx;
    s.addEventListener("input", () => {
      state.audio.sfx = parseFloat(s.value);
      setAudioVolumes();
      savePersistedState();
    });
  }

  if (dumpBtn) {
    dumpBtn.addEventListener("click", () => {
      log("PERSIST DUMP:");
      log(JSON.stringify({ ui: state.ui, audio: state.audio }, null, 2));
    });
  }

  const pstatus = qs("#persist-status");
  if (pstatus) {
    pstatus.textContent = state.persist.enabled
      ? "Persistence: localStorage active."
      : "Persistence: localStorage only (no /persist disk check).";
  }
}

/* ------------------ Multitasking loops ------------------ */

function startLoops() {
  setInterval(updateClock, 1000);
  setInterval(() => {
    reactorTick();
    containmentTick();
  }, 800);
  setInterval(() => {
    networkTick();
    updateCoreStatusBoard();
  }, 1000);
}

/* ------------------ Plugins (example) ------------------ */

registerPlugin({
  id: "audio-reactor",
  init({ bus }) {
    bus.on("reactor-status-changed", (status) => {
      if (status === "NOMINAL") setMusicTrack("normal");
      else if (status === "STRESSED") setMusicTrack("stress");
      else if (status === "CRITICAL") {
        setMusicTrack("meltdown");
        if (audioHandles.sfx.alarm) tryPlay(audioHandles.sfx.alarm);
      }
    });
  },
});

/* ------------------ Boot ------------------ */

window.addEventListener("DOMContentLoaded", () => {
  loadPersistedState();
  initAudio();
  updateClock();
  updateCoreStatusBoard();
  updateReactorUI();
  updateNetworkUI();
  updateContainmentUI();

  attachTaskbarHandlers();
  attachTopbarButtons();
  attachLeverHandlers();
  attachCoolantHandlers();
  attachConsoleInput();
  attachSettingsHandlers();
  attachHotkeys();

  setActiveApp(state.ui.activeApp || "core");
  startLoops();

  log("ChernOS v2.0.0 reactor shell online.");
  savePersistedState();
});
