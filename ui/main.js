// ChernOS v2.0.0 – main reactor UI logic

// ---------- Utility helpers ----------

const clamp = (v, min, max) => Math.min(max, Math.max(min, v));
const randRange = (min, max) => min + Math.random() * (max - min);
const choose = (arr) => arr[Math.floor(Math.random() * arr.length)];

// Simple internal message bus
class Bus {
  constructor() {
    this.listeners = new Map();
  }
  on(evt, handler) {
    if (!this.listeners.has(evt)) this.listeners.set(evt, new Set());
    this.listeners.get(evt).add(handler);
  }
  emit(evt, payload) {
    const set = this.listeners.get(evt);
    if (!set) return;
    for (const h of set) h(payload);
  }
}

const bus = new Bus();

// ---------- Audio engine (Web Audio, no external files) ----------

class SoundEngine {
  constructor() {
    this.ctx = null;
    this.coreHum = null;
    this.alarmsEnabled = true;
  }

  ensureContext() {
    if (!this.ctx) {
      this.ctx = new (window.AudioContext || window.webkitAudioContext)();
    }
  }

  startCoreHum() {
    this.ensureContext();
    if (this.coreHum) return;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = "sawtooth";
    osc.frequency.value = 55; // low hum
    gain.gain.value = 0.03; // quiet
    osc.connect(gain);
    gain.connect(this.ctx.destination);
    osc.start();
    this.coreHum = { osc, gain };
  }

  stopCoreHum() {
    if (!this.coreHum) return;
    this.coreHum.osc.stop();
    this.coreHum.osc.disconnect();
    this.coreHum.gain.disconnect();
    this.coreHum = null;
  }

  playAlarm() {
    if (!this.alarmsEnabled) return;
    this.ensureContext();
    const duration = 0.25;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = "square";
    osc.frequency.setValueAtTime(880, this.ctx.currentTime);
    gain.gain.setValueAtTime(0.2, this.ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + duration);
    osc.connect(gain);
    gain.connect(this.ctx.destination);
    osc.start();
    osc.stop(this.ctx.currentTime + duration);
  }
}

const sound = new SoundEngine();

// ---------- Reactor simulation ----------

class Reactor {
  constructor() {
    this.tempK = 275; // kelvin
    this.powerTW = 0.42;
    this.pressureMPa = 1.0;
    this.coolantPct = 0.62;
    this.meltdown = 0.0; // 0–1
    this.manualCoolantBias = 0;
  }

  tick(dt) {
    // Base heating/cooling dynamics
    const targetPower = 0.4 + this.meltdown * 1.2;
    this.powerTW += (targetPower - this.powerTW) * dt * 0.3;

    const targetTemp = 270 + this.powerTW * 80 - this.coolantPct * 40;
    this.tempK += (targetTemp - this.tempK) * dt * 0.7;

    const targetPressure = 0.9 + this.powerTW * 0.4;
    this.pressureMPa += (targetPressure - this.pressureMPa) * dt * 0.5;

    // Coolant naturally drifts towards 0.6 plus manual bias
    const targetCoolant = clamp(0.6 + this.manualCoolantBias, 0.1, 1.0);
    this.coolantPct += (targetCoolant - this.coolantPct) * dt * 0.8;

    // Meltdown progression if temp too high/pressure too high
    const tempDanger = clamp((this.tempK - 310) / 60, 0, 1);
    const pressureDanger = clamp((this.pressureMPa - 1.4) / 0.8, 0, 1);
    const danger = Math.max(tempDanger, pressureDanger);
    this.meltdown = clamp(this.meltdown + danger * dt * 0.05 - dt * 0.01, 0, 1);

    // Emit updates
    bus.emit("reactor:update", {
      tempK: this.tempK,
      powerTW: this.powerTW,
      pressureMPa: this.pressureMPa,
      coolantPct: this.coolantPct,
      meltdown: this.meltdown,
    });
  }

  manualCoolant(delta) {
    this.manualCoolantBias = clamp(this.manualCoolantBias + delta, -0.3, 0.3);
    bus.emit("reactor:manualCoolant", { bias: this.manualCoolantBias });
  }
}

// ---------- Fault engine ----------

class FaultEngine {
  constructor(reactor) {
    this.reactor = reactor;
    this.auto = true;
  }

  randomFault() {
    const types = [
      "SENSOR_GLITCH",
      "PUMP_STALL",
      "PRESSURE_SPIKE",
      "GHOST_RADIATION",
      "NET_PARTITION",
    ];
    const t = choose(types);
    let severity = randRange(0.1, 0.6);

    switch (t) {
      case "SENSOR_GLITCH":
        // cosmetic; just log
        break;
      case "PUMP_STALL":
        this.reactor.coolantPct = clamp(this.reactor.coolantPct - 0.15, 0.05, 1);
        break;
      case "PRESSURE_SPIKE":
        this.reactor.pressureMPa += randRange(0.2, 0.5);
        break;
      case "GHOST_RADIATION":
        this.reactor.tempK += randRange(10, 25);
        break;
      case "NET_PARTITION":
        bus.emit("net:partition", {});
        break;
    }

    bus.emit("fault:event", {
      type: t,
      severity,
      ts: new Date(),
    });
  }

  tick(dt) {
    if (!this.auto) return;
    // Roughly one fault every 20–40 seconds
    if (Math.random() < dt / randRange(20, 40)) {
      this.randomFault();
    }
  }
}

// ---------- Network engine ----------

class NetworkEngine {
  constructor() {
    this.packetsPerSec = 0;
    this.latencyMs = 2.7;
    this.partitioned = false;
  }

  tick(dt) {
    const basePackets = this.partitioned ? 5 : 180;
    const jitter = randRange(-20, 20);
    this.packetsPerSec = clamp(basePackets + jitter, 0, 400);

    const baseLatency = this.partitioned ? 35 : 3;
    this.latencyMs = clamp(baseLatency + randRange(-0.6, 0.6), 1, 60);

    bus.emit("net:update", {
      packetsPerSec: this.packetsPerSec,
      latencyMs: this.latencyMs,
      partitioned: this.partitioned,
    });
  }
}

// ---------- UI Controller ----------

class UI {
  constructor(reactor, faults, net) {
    this.reactor = reactor;
    this.faults = faults;
    this.net = net;
    this.bootLocked = true;
    this.lastTs = performance.now();
    this.meltdownTriggered = false;

    // DOM refs
    this.dom = {
      bootOverlay: document.getElementById("boot-overlay"),
      bootButton: document.getElementById("boot-start"),
      bootLog: document.getElementById("boot-log"),

      coreMode: document.getElementById("core-mode"),
      coreTempRing: document.getElementById("core-temp-ring"),
      coreTempValue: document.getElementById("core-temp-value"),
      coreOutput: document.getElementById("core-output"),
      gaugePressure: document.getElementById("gauge-pressure"),
      gaugePressureValue: document.getElementById("gauge-pressure-value"),
      gaugeCoolant: document.getElementById("gauge-coolant"),
      gaugeCoolantValue: document.getElementById("gauge-coolant-value"),

      coolantMinus: document.getElementById("coolant-minus"),
      coolantPlus: document.getElementById("coolant-plus"),
      coolantManualState: document.getElementById("coolant-manual-state"),

      flagContainment: document.getElementById("flag-containment"),
      flagSafeguard: document.getElementById("flag-safeguard"),

      pillReactor: document.getElementById("pill-reactor"),
      pillShield: document.getElementById("pill-shield"),
      pillNet: document.getElementById("pill-net"),
      netMode: document.getElementById("net-mode"),
      netPackets: document.getElementById("net-packets"),
      netLatency: document.getElementById("net-latency"),

      eventLog: document.getElementById("event-log"),
      meltdownFill: document.getElementById("meltdown-fill"),
      meltdownValue: document.getElementById("meltdown-value"),
      meltdownState: document.getElementById("meltdown-state"),

      toggleNight: document.getElementById("toggle-night"),
      toggleAlarms: document.getElementById("toggle-alarms"),
      toggleAutofault: document.getElementById("toggle-autofault"),

      btnSimFault: document.getElementById("btn-simulate-fault"),
      btnAudioTest: document.getElementById("btn-audio-test"),

      footerLeft: document.getElementById("footer-left"),
    };
  }

  init() {
    // Boot button
    this.dom.bootButton.addEventListener("click", () => {
      if (!this.bootLocked) return;
      this.appendBootLog("> HUMAN CONFIRMATION ACCEPTED");
      this.appendBootLog("> BRINGING CORE ONLINE…");
      this.bootLocked = false;
      sound.startCoreHum();
      setTimeout(() => {
        this.dom.bootOverlay.classList.add("bc-boot-overlay--hidden");
      }, 800);
    });

    // Manual coolant controls
    this.dom.coolantMinus.addEventListener("mousedown", () =>
      this.reactor.manualCoolant(-0.05)
    );
    this.dom.coolantPlus.addEventListener("mousedown", () =>
      this.reactor.manualCoolant(0.05)
    );

    // Toggles
    this.dom.toggleNight.addEventListener("change", () => {
      document.body.classList.toggle(
        "bc-night",
        this.dom.toggleNight.checked
      );
    });
    this.dom.toggleAlarms.addEventListener("change", () => {
      sound.alarmsEnabled = this.dom.toggleAlarms.checked;
    });
    this.dom.toggleAutofault.addEventListener("change", () => {
      this.faults.auto = this.dom.toggleAutofault.checked;
    });

    // Buttons
    this.dom.btnSimFault.addEventListener("click", () => {
      this.faults.randomFault();
      sound.playAlarm();
    });
    this.dom.btnAudioTest.addEventListener("click", () => {
      sound.startCoreHum();
      sound.playAlarm();
    });

    // Bus listeners
    bus.on("reactor:update", (s) => this.updateReactorUI(s));
    bus.on("reactor:manualCoolant", (s) => this.updateCoolantBias(s));
    bus.on("fault:event", (f) => this.handleFault(f));
    bus.on("net:update", (n) => this.updateNetUI(n));
    bus.on("net:partition", () => this.handleNetPartition());

    // Start main loop
    requestAnimationFrame(this.loop.bind(this));
  }

  appendBootLog(line) {
    const el = document.createElement("div");
    el.textContent = line;
    this.dom.bootLog.appendChild(el);
    this.dom.bootLog.scrollTop = this.dom.bootLog.scrollHeight;
  }

  updateReactorUI({ tempK, powerTW, pressureMPa, coolantPct, meltdown }) {
    const tempRounded = Math.round(tempK);
    this.dom.coreTempValue.textContent = `${tempRounded}K`;
    this.dom.coreOutput.textContent = `${powerTW.toFixed(2)} TW`;

    // Temperature ring color and glow
    const tempNorm = clamp((tempK - 260) / 100, 0, 1); // 0..1
    const hue = 180 - tempNorm * 180; // green->red
    this.dom.coreTempRing.style.setProperty(
      "--core-temp-hue",
      hue.toString()
    );
    this.dom.coreTempRing.style.setProperty(
      "--core-temp-intensity",
      (0.3 + tempNorm * 0.7).toString()
    );

    // Gauges
    const pPct = clamp((pressureMPa - 0.5) / 2.0, 0, 1);
    this.dom.gaugePressure.style.width = `${pPct * 100}%`;
    this.dom.gaugePressureValue.textContent = `${pressureMPa.toFixed(2)} MPa`;

    const cPct = clamp(coolantPct, 0, 1);
    this.dom.gaugeCoolant.style.width = `${cPct * 100}%`;
    this.dom.gaugeCoolantValue.textContent = `${Math.round(
      cPct * 100
    )} %`;

    // Meltdown meter
    const mPct = Math.round(meltdown * 100);
    this.dom.meltdownFill.style.width = `${mPct}%`;
    this.dom.meltdownValue.textContent = `${mPct} %`;

    if (meltdown > 0.8 && !this.meltdownTriggered) {
      this.triggerMeltdown();
    }

    // Mode display
    if (meltdown > 0.8) {
      this.dom.coreMode.textContent = "MODE: MELTDOWN AFTERMATH";
      this.dom.pillReactor.className =
        "bc-status-pill bc-status-pill--crit";
      this.dom.pillReactor.textContent = "REACTOR · COLLAPSED";
    } else if (meltdown > 0.4) {
      this.dom.coreMode.textContent = "MODE: CRITICAL EDGE";
      this.dom.pillReactor.className =
        "bc-status-pill bc-status-pill--warn";
      this.dom.pillReactor.textContent = "REACTOR · UNSTABLE";
    } else {
      this.dom.coreMode.textContent = "MODE: STABLE RUN";
      this.dom.pillReactor.className =
        "bc-status-pill bc-status-pill--ok";
      this.dom.pillReactor.textContent = "REACTOR · NOMINAL";
    }
  }

  updateCoolantBias({ bias }) {
    const v = Math.round(bias * 100);
    if (Math.abs(v) < 5) {
      this.dom.coolantManualState.textContent = "AUTO";
    } else if (v > 0) {
      this.dom.coolantManualState.textContent = `INJECT +${v}%`;
    } else {
      this.dom.coolantManualState.textContent = `DIVERT ${v}%`;
    }
  }

  handleFault({ type, severity, ts }) {
    const row = document.createElement("div");
    row.className = "bc-event-row";

    const tsStr = ts.toLocaleTimeString("en-GB", { hour12: false });
    const sevTag =
      severity > 0.5 ? "CRIT" : severity > 0.3 ? "WARN" : "INFO";

    row.innerHTML = `
      <span class="bc-event-ts">${tsStr}</span>
      <span class="bc-event-type">${type}</span>
      <span class="bc-event-sev bc-event-sev--${sevTag.toLowerCase()}">${sevTag}</span>
    `;

    this.dom.eventLog.prepend(row);
    sound.playAlarm();

    while (this.dom.eventLog.children.length > 40) {
      this.dom.eventLog.removeChild(this.dom.eventLog.lastChild);
    }
  }

  updateNetUI({ packetsPerSec, latencyMs, partitioned }) {
    this.dom.netPackets.textContent = packetsPerSec.toFixed(0);
    this.dom.netLatency.textContent = latencyMs.toFixed(1);

    if (partitioned) {
      this.dom.netMode.textContent = "MODE: PARTITIONED";
      this.dom.pillNet.className =
        "bc-status-pill bc-status-pill--warn";
      this.dom.pillNet.textContent = "DIAG-NET · DEGRADED";
    } else {
      this.dom.netMode.textContent = "MODE: STABLE";
      this.dom.pillNet.className =
        "bc-status-pill bc-status-pill--idle";
      this.dom.pillNet.textContent = "DIAG-NET · LINKED";
    }
  }

  handleNetPartition() {
    // cosmetic hook; could flash nodes etc.
    this.dom.footerLeft.textContent =
      "INTERNAL BUS: NET_PARTITION EVENT · PLUGINS: core, net, faults";
  }

  triggerMeltdown() {
    this.meltdownTriggered = true;
    document.body.classList.add("bc-meltdown");
    this.dom.meltdownState.textContent = "MELTDOWN: AFTERMATH MODE";
    this.dom.flagContainment.className =
      "bc-flag bc-flag--crit";
    this.dom.flagContainment.textContent =
      "SECONDARY CONTAINMENT · VENTING";
    this.dom.flagSafeguard.className =
      "bc-flag bc-flag--warn";
    this.dom.flagSafeguard.textContent =
      "SAFEGUARD RECHARGE · EXHAUSTED";
    this.appendEvent(
      "MELTDOWN_AFTER",
      "CRIT",
      "CORE COLLAPSE RECORDED – AFTERMATH MODE ONLY"
    );
  }

  appendEvent(type, sev, msg) {
    const row = document.createElement("div");
    const tsStr = new Date().toLocaleTimeString("en-GB", {
      hour12: false,
    });
    row.className = "bc-event-row";
    row.innerHTML = `
      <span class="bc-event-ts">${tsStr}</span>
      <span class="bc-event-type">${type}</span>
      <span class="bc-event-msg">${msg}</span>
      <span class="bc-event-sev bc-event-sev--${sev.toLowerCase()}">${sev}</span>
    `;
    this.dom.eventLog.prepend(row);
  }

  loop(ts) {
    const dt = Math.min((ts - this.lastTs) / 1000, 0.2);
    this.lastTs = ts;

    if (!this.bootLocked) {
      this.reactor.tick(dt);
      this.faults.tick(dt);
      this.net.tick(dt);
    }

    requestAnimationFrame(this.loop.bind(this));
  }
}

// ---------- Bootstrap ----------

window.addEventListener("DOMContentLoaded", () => {
  const reactor = new Reactor();
  const faults = new FaultEngine(reactor);
  const net = new NetworkEngine();
  const ui = new UI(reactor, faults, net);
  ui.init();
});
