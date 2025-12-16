(() => {
  const $ = (id) => document.getElementById(id);

  const state = {
    engaged: false,
    night: false,
    alarmArmed: false,
    temp: 412,
    flow: 68,
    containment: 91,
    tick: 0,
    net: {
      "CORE-1": { status: "ONLINE", latency: 4 },
      "FLOW-A": { status: "NOMINAL", latency: 11 },
      "SHIELD-X": { status: "STABLE", latency: 7 },
      "DIAG-NET": { status: "READY", latency: 2 },
      "OPS-TOWER": { status: "ONLINE", latency: 9 }
    }
  };

  // ---------- Audio (synthetic reactor hum + alarm) ----------
  let audioCtx = null;
  let humOsc = null;
  let humGain = null;

  function ensureAudio() {
    if (audioCtx) return;
    audioCtx = new (window.AudioContext || window.webkitAudioContext)();

    humOsc = audioCtx.createOscillator();
    humGain = audioCtx.createGain();

    humOsc.type = "sawtooth";
    humOsc.frequency.value = 52;

    humGain.gain.value = 0.0;

    humOsc.connect(humGain);
    humGain.connect(audioCtx.destination);
    humOsc.start();
  }

  function setHum(on) {
    ensureAudio();
    const target = on ? 0.04 : 0.0;
    humGain.gain.setTargetAtTime(target, audioCtx.currentTime, 0.15);
  }

  function beepAlarm() {
    ensureAudio();
    const o = audioCtx.createOscillator();
    const g = audioCtx.createGain();
    o.type = "square";
    o.frequency.value = 880;
    g.gain.value = 0.0;
    o.connect(g);
    g.connect(audioCtx.destination);
    o.start();

    g.gain.setTargetAtTime(0.12, audioCtx.currentTime, 0.01);
    g.gain.setTargetAtTime(0.0, audioCtx.currentTime + 0.25, 0.05);
    o.stop(audioCtx.currentTime + 0.35);
  }

  // ---------- UI helpers ----------
  function setPill(id, text) {
    const el = $(id);
    if (el) el.textContent = text;
  }

  function clamp(n, a, b) {
    return Math.max(a, Math.min(b, n));
  }

  // ---------- Ring render ----------
  function drawRing(temp) {
    const c = $("ring");
    if (!c) return;
    const ctx = c.getContext("2d");
    const w = c.width, h = c.height;
    const cx = w / 2, cy = h / 2;

    ctx.clearRect(0, 0, w, h);

    const r = 110;
    const start = -Math.PI * 0.75;
    const end = Math.PI * 0.75;
    const t = clamp((temp - 250) / 650, 0, 1);

    // base arc
    ctx.lineWidth = 18;
    ctx.strokeStyle = "rgba(120, 255, 200, 0.12)";
    ctx.beginPath();
    ctx.arc(cx, cy, r, start, end);
    ctx.stroke();

    // value arc
    ctx.lineWidth = 18;
    ctx.strokeStyle = "rgba(120, 255, 200, 0.8)";
    ctx.shadowBlur = 18;
    ctx.shadowColor = "rgba(120, 255, 200, 0.6)";
    ctx.beginPath();
    ctx.arc(cx, cy, r, start, start + (end - start) * t);
    ctx.stroke();

    ctx.shadowBlur = 0;

    // tick marks
    ctx.strokeStyle = "rgba(120,255,200,0.18)";
    ctx.lineWidth = 2;
    for (let i = 0; i <= 12; i++) {
      const a = start + (end - start) * (i / 12);
      const x1 = cx + Math.cos(a) * (r - 24);
      const y1 = cy + Math.sin(a) * (r - 24);
      const x2 = cx + Math.cos(a) * (r - 8);
      const y2 = cy + Math.sin(a) * (r - 8);
      ctx.beginPath();
      ctx.moveTo(x1, y1);
      ctx.lineTo(x2, y2);
      ctx.stroke();
    }
  }

  // ---------- Topology ----------
  function renderTopology() {
    const host = $("topology");
    if (!host) return;

    const nodes = Object.keys(state.net);
    host.innerHTML = "";

    for (const name of nodes) {
      const n = state.net[name];
      const card = document.createElement("div");
      card.className = "node";

      const h = document.createElement("div");
      h.className = "node-h";
      h.textContent = name;

      const s = document.createElement("div");
      s.className = "node-s";
      s.textContent = `${n.status} • ${n.latency}ms`;

      card.appendChild(h);
      card.appendChild(s);

      host.appendChild(card);
    }
  }

  // ---------- Terminal ----------
  function logLine(msg) {
    const log = $("termLog");
    if (!log) return;
    const line = document.createElement("div");
    line.className = "term-line";
    line.textContent = msg;
    log.appendChild(line);
    log.scrollTop = log.scrollHeight;
  }

  function cmdSimulate(kind) {
    const known = ["sensor", "pump", "pressure", "ghost-rad", "meltdown"];
    if (!known.includes(kind)) {
      logLine(`ERR: unknown fault "${kind}"`);
      return;
    }

    if (kind === "meltdown") {
      state.temp = 980;
      state.flow = 12;
      state.containment = 23;
      state.net["CORE-1"].status = "CRITICAL";
      state.net["SHIELD-X"].status = "BREACH";
      state.alarmArmed = true;
      setPill("pill-mode", "MODE: MELTDOWN");
      beepAlarm();
      logLine("EVENT: MELTDOWN SIMULATION ACTIVE");
      return;
    }

    logLine(`EVENT: fault injected -> ${kind}`);
    // small perturbations
    if (kind === "sensor") state.net["DIAG-NET"].status = "FAULT";
    if (kind === "pump") state.flow = clamp(state.flow - 20, 0, 100);
    if (kind === "pressure") state.containment = clamp(state.containment - 18, 0, 100);
    if (kind === "ghost-rad") state.net["OPS-TOWER"].status = "ANOMALY";
    beepAlarm();
  }

  function cmdNet(sub) {
    const valid = ["status", "scan", "trace", "throttle"];
    if (!valid.includes(sub)) {
      logLine("ERR: net requires status|scan|trace|throttle");
      return;
    }
    if (sub === "status") {
      logLine("NET: " + Object.entries(state.net).map(([k, v]) => `${k}=${v.status}`).join(" | "));
    } else if (sub === "scan") {
      logLine("NET: scanning… found 5 nodes; 0 external routes (kiosk).");
    } else if (sub === "trace") {
      logLine("NET: trace DIAG-NET -> CORE-1: 2 hops, 6ms avg.");
    } else if (sub === "throttle") {
      logLine("NET: throttle engaged. latency +8ms (simulated).");
      for (const k of Object.keys(state.net)) state.net[k].latency += 8;
    }
  }

  function cmdAudio(parts) {
    if (parts[0] === "mute") {
      setHum(false);
      logLine("AUDIO: muted");
      return;
    }
    if (parts[0] === "test") {
      const id = parts[1] || "0";
      logLine(`AUDIO: test ${id}`);
      beepAlarm();
      return;
    }
    logLine("ERR: audio requires test <id> | mute");
  }

  function handleCommand(raw) {
    const input = raw.trim();
    if (!input) return;

    logLine(`> ${input}`);

    const parts = input.split(/\s+/);
    const cmd = parts[0].toLowerCase();

    if (cmd === "help") {
      logLine("commands: simulate <fault> | net <op> | audio <op> | clear");
      return;
    }
    if (cmd === "clear") {
      $("termLog").innerHTML = "";
      return;
    }
    if (cmd === "simulate") {
      cmdSimulate((parts[1] || "").toLowerCase());
      return;
    }
    if (cmd === "net") {
      cmdNet((parts[1] || "").toLowerCase());
      return;
    }
    if (cmd === "audio") {
      cmdAudio(parts.slice(1).map(x => x.toLowerCase()));
      return;
    }

    logLine(`ERR: unknown command "${cmd}" (try "help")`);
  }

  // ---------- Update loop ----------
  function updateMeters() {
    $("tempValue").textContent = String(Math.round(state.temp));
    $("flowBar").style.width = `${clamp(state.flow, 0, 100)}%`;
    $("contBar").style.width = `${clamp(state.containment, 0, 100)}%`;

    $("shieldV").textContent = state.net["SHIELD-X"].status;
    $("flowV").textContent = state.net["FLOW-A"].status;
    $("opsV").textContent = state.net["OPS-TOWER"].status;
    $("diagV").textContent = state.net["DIAG-NET"].status;

    $("safePct").textContent = String($("safeguard").value);
  }

  function tick() {
    state.tick++;

    // gentle simulated dynamics (unless meltdown)
    if (state.temp < 900) {
      const wobble = Math.sin(state.tick / 18) * 3;
      state.temp = clamp(state.temp + wobble * 0.2, 320, 620);
      state.flow = clamp(state.flow + Math.sin(state.tick / 40) * 0.6, 40, 92);
      state.containment = clamp(state.containment + Math.cos(state.tick / 60) * 0.4, 70, 98);
    }

    const d = new Date();
    setPill("pill-time", d.toLocaleTimeString());

    drawRing(state.temp);
    updateMeters();

    if (state.alarmArmed && state.tick % 90 === 0) beepAlarm();

    if (state.tick % 120 === 0) renderTopology();
    requestAnimationFrame(tick);
  }

  // ---------- Wiring ----------
  function wire() {
    $("engage").addEventListener("click", async () => {
      $("boot").style.display = "none";
      state.engaged = true;
      setHum(true);
      logLine("SYSTEM: console engaged");
      logLine('TIP: try "help"');
    });

    $("btn-night").addEventListener("click", () => {
      state.night = !state.night;
      document.body.classList.toggle("night", state.night);
      setPill("pill-mode", state.night ? "MODE: NIGHT" : "MODE: NORMAL");
      logLine(`MODE: ${state.night ? "night shift" : "normal"}`);
    });

    $("btn-alarm").addEventListener("click", () => {
      state.alarmArmed = !state.alarmArmed;
      logLine(`ALARM: ${state.alarmArmed ? "armed" : "disarmed"}`);
      if (state.alarmArmed) beepAlarm();
    });

    $("btn-meltdown").addEventListener("click", () => {
      cmdSimulate("meltdown");
    });

    $("safeguard").addEventListener("input", (e) => {
      $("safePct").textContent = String(e.target.value);
    });

    $("termForm").addEventListener("submit", (e) => {
      e.preventDefault();
      const v = $("termInput").value;
      $("termInput").value = "";
      handleCommand(v);
    });
  }

  document.addEventListener("DOMContentLoaded", () => {
    wire();
    renderTopology();
    updateMeters();
    drawRing(state.temp);
    tick();
  });
})();
