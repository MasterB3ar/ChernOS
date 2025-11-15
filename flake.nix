{
  description = "ChernOS v1.3.0 — Meltdown Protocol";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    pkgs = import nixpkgs { inherit system; };

    # ---------- GRUB THEME ----------
    grubTheme = pkgs.runCommand "grub-theme-chernos" {} ''
      mkdir -p $out/share/grub/themes/chernos
      cat > $out/share/grub/themes/chernos/theme.txt <<EOF
terminal_output gfxterm
color_normal cfeecb 000000
color_highlight bff9a8 000000

menuentry "ChernOS Live" {
  set gfxpayload=keep
}
EOF
    '';

    # ---------- PLYMOUTH THEME ----------
    plymouthTheme = pkgs.runCommand "plymouth-theme-chernos" {} ''
      mkdir -p $out/share/plymouth/themes/chernos

      cat > $out/share/plymouth/themes/chernos/chernos.plymouth <<EOF
[Plymouth Theme]
Name=ChernOS
Description=Nuclear green boot glow
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/chernos
ScriptFile=/usr/share/plymouth/themes/chernos/chernos.script
EOF

      cat > $out/share/plymouth/themes/chernos/chernos.script <<'EOF'
Window.SetBackgroundTopColor (0.0, 0.02, 0.01);
Window.SetBackgroundBottomColor (0.0, 0.0, 0.0);
EOF
    '';

    # ---------- Optional persistence helper ----------
    mountHelper = pkgs.writeShellScriptBin "chernos-persist-helper" ''
      set -eu

      if [ -e /dev/disk/by-label/CHERNOS_PERSIST ]; then
        mkdir -p /persist
        mount -o rw,noatime /dev/disk/by-label/CHERNOS_PERSIST /persist || true
        mkdir -p /persist/chernos-logs
        touch /persist/chernos-logs/.persist-ok || true
        echo "export CHERNOS_PERSIST=1" > /run/chernos-persist.env
      fi
    '';

    # ---------- ChernOS UI (HTML + JS) ----------
    chernosPage = pkgs.writeText "index.html" ''
      <!doctype html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <title>ChernOS v1.3.0 – Meltdown Protocol</title>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <script src="https://cdn.tailwindcss.com"></script>
        <style>
          :root {
            --nuclear-green: #bff9a8;
            --bg-deep: #020806;
          }
          * { box-sizing: border-box; }
          body {
            margin: 0;
            background:
              radial-gradient(circle at 20% 0%, rgba(0,255,140,0.06), transparent 60%),
              radial-gradient(circle at 85% 0%, rgba(0,255,140,0.03), transparent 55%),
              var(--bg-deep);
            color: #cfeecb;
            font-family: system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, sans-serif;
            overflow: hidden;
          }
          .wrap {
            min-height: 100vh;
            padding: 22px 30px;
            display: flex;
            flex-direction: column;
            gap: 12px;
            position: relative;
          }
          .reactor-glow {
            position: fixed;
            inset: -40px;
            pointer-events: none;
            background:
              radial-gradient(circle at 15% 10%, rgba(0,255,140,0.05), transparent 70%),
              radial-gradient(circle at 80% -10%, rgba(0,255,140,0.04), transparent 70%);
            mix-blend-mode: screen;
            opacity: 0.6;
            animation: glowPulse 4s ease-in-out infinite alternate;
          }
          @keyframes glowPulse {
            0% { opacity: 0.35; filter: blur(0); }
            100% { opacity: 0.9; filter: blur(1px); }
          }
          .card {
            border-radius: 16px;
            border: 1px solid rgba(191,249,168,0.16);
            background: radial-gradient(circle at top, rgba(0,255,140,0.04), transparent 90%) rgba(0,0,0,0.45);
            padding: 12px 16px;
            backdrop-filter: blur(10px);
            box-shadow: 0 0 26px rgba(0,0,0,0.75);
          }
          .label {
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 1.2px;
            color: #9ca3af;
          }
          .big {
            font-size: 24px;
            font-weight: 600;
            color: var(--nuclear-green);
          }
          .grid-4 {
            display: grid;
            grid-template-columns: repeat(4, minmax(0,1fr));
            gap: 9px;
          }
          .pill {
            font-size: 9px;
            padding: 3px 8px;
            border-radius: 999px;
            border: 1px solid rgba(191,249,168,0.22);
            color: #9ca3af;
          }
          .btn {
            padding: 5px 9px;
            border-radius: 6px;
            border: 1px solid rgba(191,249,168,0.25);
            font-size: 10px;
            color: var(--nuclear-green);
            background: transparent;
            cursor: pointer;
            transition: all 0.16s ease-out;
          }
          .btn:hover {
            background: rgba(191,249,168,0.16);
            box-shadow: 0 0 12px rgba(191,249,168,0.18);
          }
          .toolbar {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            align-items: center;
            justify-content: space-between;
          }
          .badge {
            font-size: 9px;
            padding: 2px 7px;
            border-radius: 999px;
            border: 1px solid rgba(191,249,168,0.32);
            color: var(--nuclear-green);
          }
          .status-board {
            display: grid;
            grid-template-columns: repeat(3, minmax(0,1fr));
            gap: 6px;
            margin-top: 4px;
          }
          .status-cell {
            font-size: 9px;
            padding: 4px 6px;
            border-radius: 8px;
            border: 1px solid rgba(191,249,168,0.16);
            background: rgba(0,0,0,0.7);
            color: #9ca3af;
            position: relative;
            overflow: hidden;
          }
          .status-cell::after {
            content: "";
            position: absolute;
            inset: 0;
            background: linear-gradient(to bottom, rgba(191,249,168,0.05), transparent);
            mix-blend-mode: screen;
            opacity: 0;
            animation: flicker 3.4s infinite;
          }
          @keyframes flicker {
            0%,82%,100% { opacity: 0; }
            85% { opacity: 0.18; }
            87% { opacity: 0.02; }
            90% { opacity: 0.15; }
            93% { opacity: 0; }
          }
          .core-ring-wrap {
            position: relative;
            width: 90px;
            height: 90px;
          }
          .core-ring {
            position: absolute;
            inset: 0;
            border-radius: 50%;
            border: 2px solid rgba(191,249,168,0.26);
            box-shadow: 0 0 12px rgba(191,249,168,0.25);
            animation: ringSpin 9s linear infinite;
          }
          .core-ring.inner {
            inset: 16px;
            border-color: rgba(191,249,168,0.45);
            animation-duration: 6s;
            animation-direction: reverse;
          }
          .core-dot {
            position: absolute;
            inset: 32px;
            border-radius: 50%;
            background: radial-gradient(circle, var(--nuclear-green), transparent);
            box-shadow: 0 0 18px rgba(191,249,168,0.9);
          }
          @keyframes ringSpin {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
          }
          .lever-wrap {
            display: flex;
            flex-direction: column;
            gap: 2px;
            font-size: 9px;
            color: #9ca3af;
          }
          .lever {
            width: 120px;
          }
          #log {
            max-height: 180px;
            overflow: auto;
            font-size: 10px;
          }
          .term {
            display: grid;
            grid-template-columns: 1fr auto;
            gap: 6px;
            margin-top: 6px;
          }
          .term input {
            width: 100%;
            background: #00000090;
            border: 1px solid rgba(191,249,168,0.25);
            border-radius: 6px;
            padding: 6px 8px;
            color: #cfeecb;
            font-size: 12px;
          }
          .graphs {
            display: grid;
            grid-template-columns: repeat(3, minmax(0,1fr));
            gap: 8px;
            margin-top: 6px;
          }
          canvas {
            width: 100%;
            height: 52px;
            border-radius: 8px;
            background: rgba(0,0,0,0.65);
            border: 1px solid rgba(191,249,168,0.20);
          }
          .diag-active {
            box-shadow: 0 0 18px rgba(191,249,168,0.22);
            border-color: rgba(191,249,168,0.48);
          }
          .mute-indicator {
            font-size: 9px;
            color: #9ca3af;
          }
        </style>
      </head>
      <body>
        <div class="reactor-glow"></div>
        <div class="wrap">
          <!-- Top bar -->
          <div class="card toolbar">
            <div>
              <div class="label">ChernOS v1.3.0</div>
              <div class="big">Meltdown Protocol</div>
              <div class="status-board">
                <div class="status-cell">CORE CHANNELS: SYNCED</div>
                <div class="status-cell">COOLANT LOOP: NOMINAL</div>
                <div class="status-cell">CONTAINMENT GRID: STABLE</div>
                <div class="status-cell">I/O BUS: GREEN</div>
                <div class="status-cell">SENSOR MESH: ONLINE</div>
                <div class="status-cell">ALERT QUEUE: IDLE</div>
              </div>
            </div>
            <div style="display:flex;flex-direction:column;gap:6px;align-items:flex-end">
              <div style="display:flex;gap:6px;align-items:center">
                <span class="badge">SIM-CORE ONLINE</span>
                <span class="badge" id="diag-badge">DIAGNOSTICS: OFF</span>
                <span class="badge" id="persist-badge">PERSISTENCE: OFF</span>
              </div>
              <div style="display:flex;gap:10px;align-items:center">
                <div class="core-ring-wrap">
                  <div class="core-ring"></div>
                  <div class="core-ring inner"></div>
                  <div class="core-dot" id="core-dot"></div>
                </div>
                <div style="display:flex;flex-direction:column;gap:4px;align-items:flex-end">
                  <button class="btn" id="diag-toggle">Diagnostics Mode</button>
                  <button class="btn" id="mute-toggle">Toggle Audio</button>
                  <span class="mute-indicator" id="mute-state">Audio: ON</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Telemetry row -->
          <div class="grid-4">
            <div class="card">
              <div class="label">CORE TEMP</div>
              <div id="temp" class="big">312°C</div>
              <div id="temp-status" style="font-size:10px;margin-top:2px;">Nominal</div>
            </div>
            <div class="card">
              <div class="label">PRESSURE COUPLING</div>
              <div id="pressure" class="big">1.30 MPa</div>
              <div id="pressure-status" style="font-size:10px;margin-top:2px;">Stable</div>
            </div>
            <div class="card">
              <div class="label">RADIATION FLUX</div>
              <div id="rad" class="big">0.14 mSv/h</div>
              <div id="rad-status" style="font-size:10px;margin-top:2px;">Shielded</div>
            </div>
            <div class="card">
              <div class="label">SAFEGUARDS</div>
              <div id="sg" class="big">3 / 3</div>
              <div style="display:flex;flex-wrap:wrap;gap:4px;margin-top:4px">
                <div class="pill">Primary SCRAM</div>
                <div class="pill">Coolant Surge</div>
                <div class="pill">Containment Seal</div>
              </div>
              <div style="margin-top:6px;display:flex;gap:8px">
                <div class="lever-wrap">
                  <span>Core Drive</span>
                  <input id="lever-core" class="lever" type="range" min="40" max="120" value="80">
                </div>
                <div class="lever-wrap">
                  <span>Coolant Bias</span>
                  <input id="lever-coolant" class="lever" type="range" min="80" max="140" value="100">
                </div>
              </div>
            </div>
          </div>

          <!-- Controls + log + terminal -->
          <div class="card">
            <div class="label">OPERATOR CONTROL SURFACE</div>
            <div style="display:flex;flex-wrap:wrap;gap:6px;margin-top:4px">
              <button class="btn" id="btn-scram">SCRAM</button>
              <button class="btn" id="btn-relief">Relief</button>
              <button class="btn" id="btn-stress">Stress Pulse</button>
              <button class="btn" id="btn-chaos">Force Failure</button>
              <button class="btn" id="btn-reset">Reset</button>
            </div>

            <div class="term">
              <input id="term-input" placeholder="terminal (help, status, log &lt;msg&gt;, power &lt;n&gt;, coolant &lt;n&gt;, diag on/off, audio on/off, save-log)">
              <button class="btn" id="term-run">Run</button>
            </div>

            <div id="log" style="margin-top:6px;line-height:1.4"></div>
          </div>

          <!-- Diagnostics graphs -->
          <div class="card" id="diag-card" style="display:none">
            <div class="label">DIAGNOSTICS MODE — TELEMETRY</div>
            <div class="graphs">
              <div>
                <div style="font-size:9px;color:#9ca3af;margin:2px 0">Core Temp</div>
                <canvas id="g-core"></canvas>
              </div>
              <div>
                <div style="font-size:9px;color:#9ca3af;margin:2px 0">Pressure</div>
                <canvas id="g-press"></canvas>
              </div>
              <div>
                <div style="font-size:9px;color:#9ca3af;margin:2px 0">Radiation</div>
                <canvas id="g-rad"></canvas>
              </div>
            </div>
          </div>
        </div>

        <script>
          // ---------- DOM refs ----------
          var logEl = document.getElementById("log");
          var tempEl = document.getElementById("temp");
          var pEl = document.getElementById("pressure");
          var rEl = document.getElementById("rad");
          var sgEl = document.getElementById("sg");
          var ts = document.getElementById("temp-status");
          var ps = document.getElementById("pressure-status");
          var rs = document.getElementById("rad-status");
          var diagToggle = document.getElementById("diag-toggle");
          var diagBadge = document.getElementById("diag-badge");
          var diagCard = document.getElementById("diag-card");
          var muteToggle = document.getElementById("mute-toggle");
          var muteState = document.getElementById("mute-state");
          var persistBadge = document.getElementById("persist-badge");
          var coreDot = document.getElementById("core-dot");

          var btnScram = document.getElementById("btn-scram");
          var btnRelief = document.getElementById("btn-relief");
          var btnStress = document.getElementById("btn-stress");
          var btnChaos = document.getElementById("btn-chaos");
          var btnReset = document.getElementById("btn-reset");

          var leverCore = document.getElementById("lever-core");
          var leverCool = document.getElementById("lever-coolant");

          var termInput = document.getElementById("term-input");
          var termRun = document.getElementById("term-run");

          // ---------- Sim state ----------
          var temp, p, rad, sg, meltdown;
          var diagnostics = false;
          var histLen = 80;
          var histTemp = [];
          var histPress = [];
          var histRad = [];

          var audioCtx = null;
          var humNode = null;
          var coolantNode = null;
          var sirenNode = null;
          var audioOn = true;

          var persistEnabled = false;

          // detect ?persist=1 in URL
          (function(){
            if (window.location.search.indexOf("persist=1") !== -1) {
              persistEnabled = true;
            }
          })();

          // ---------- Audio ----------
          function ensureAudio() {
            if (audioCtx !== null) return;
            try {
              audioCtx = new (window.AudioContext || window.webkitAudioContext)();
            } catch(e) {
              audioCtx = null;
            }
          }

          function startHum() {
            if (!audioOn || audioCtx === null || humNode) return;
            var osc = audioCtx.createOscillator();
            var g = audioCtx.createGain();
            osc.type = "sine";
            osc.frequency.value = 52;
            g.gain.value = 0.035;
            osc.connect(g);
            g.connect(audioCtx.destination);
            osc.start();
            humNode = { osc: osc, gain: g };
          }

          function stopHum() {
            if (humNode) {
              try { humNode.osc.stop(); } catch(e) {}
              humNode = null;
            }
          }

          function startCoolant() {
            if (!audioOn || audioCtx === null || coolantNode) return;
            var osc = audioCtx.createOscillator();
            var g = audioCtx.createGain();
            osc.type = "triangle";
            osc.frequency.value = 18;
            g.gain.value = 0.02;
            osc.connect(g);
            g.connect(audioCtx.destination);
            osc.start();
            coolantNode = { osc: osc, gain: g };
          }

          function stopCoolant() {
            if (coolantNode) {
              try { coolantNode.osc.stop(); } catch(e) {}
              coolantNode = null;
            }
          }

          function startSiren() {
            if (!audioOn || audioCtx === null || sirenNode) return;
            var osc = audioCtx.createOscillator();
            var g = audioCtx.createGain();
            osc.type = "square";
            g.gain.value = 0.0;
            osc.connect(g);
            g.connect(audioCtx.destination);
            osc.start();
            var up = true;
            var iv = setInterval(function(){
              if (!audioOn) {
                g.gain.value = 0;
                return;
              }
              up = !up;
              osc.frequency.value = up ? 700 : 520;
              g.gain.value = up ? 0.06 : 0.0;
            }, 260);
            sirenNode = { osc: osc, gain: g, interval: iv };
          }

          function stopSiren() {
            if (sirenNode) {
              clearInterval(sirenNode.interval);
              try { sirenNode.osc.stop(); } catch(e) {}
              sirenNode = null;
            }
          }

          function setAudioOn(on) {
            audioOn = on;
            if (on) {
              ensureAudio();
              startHum();
              startCoolant();
              if (meltdown) startSiren();
              muteState.textContent = "Audio: ON";
            } else {
              stopHum();
              stopCoolant();
              stopSiren();
              muteState.textContent = "Audio: OFF";
            }
          }

          muteToggle.addEventListener("click", function(){
            setAudioOn(!audioOn);
          });

          window.addEventListener("load", function(){
            setTimeout(function(){
              ensureAudio();
              setAudioOn(true);
            }, 400);
          });

          // ---------- Logs & persistence ----------
          function maybePersist(line) {
            if (!persistEnabled) return;
            try {
              if (navigator.sendBeacon) {
                var blob = new Blob([line], { type: "text/plain" });
                navigator.sendBeacon("/persist/chernos-logs/log.txt", blob);
              }
            } catch(e) {}
          }

          function log(msg) {
            var t = new Date().toISOString().slice(11,19);
            var line = "[" + t + "] " + msg;
            var el = document.createElement("div");
            el.textContent = line;
            logEl.prepend(el);
            maybePersist(line + "\n");
          }

          function updatePersistBadge() {
            persistBadge.textContent = "PERSISTENCE: " + (persistEnabled ? "ON" : "OFF");
            persistBadge.style.color = persistEnabled ? "#bbf7d0" : "#9ca3af";
          }

          // ---------- Graph helpers ----------
          function pushHist(buf,v) {
            buf.push(v);
            if (buf.length > histLen) buf.shift();
          }

          function drawGraph(id,data,color) {
            var c = document.getElementById(id);
            if (!c) return;
            var ctx = c.getContext("2d");
            var w = c.width;
            var h = c.height;
            ctx.clearRect(0,0,w,h);
            if (data.length < 2) return;

            var min = data[0];
            var max = data[0];
            for (var i=1;i<data.length;i++) {
              if (data[i] < min) min = data[i];
              if (data[i] > max) max = data[i];
            }
            var span = max - min;
            if (span === 0) span = 1;

            ctx.beginPath();
            ctx.strokeStyle = color;
            ctx.lineWidth = 1;

            for (var j=0;j<data.length;j++) {
              var x = (j / (data.length - 1)) * (w - 4) + 2;
              var y = h - 4 - ((data[j] - min) / span) * (h - 8);
              if (j === 0) ctx.moveTo(x,y);
              else ctx.lineTo(x,y);
            }
            ctx.stroke();
          }

          function renderGraphs() {
            if (!diagnostics) return;
            drawGraph("g-core", histTemp, "#bff9a8");
            drawGraph("g-press", histPress, "#86efac");
            drawGraph("g-rad", histRad, "#22c55e");
          }

          // ---------- Render ----------
          function render() {
            tempEl.textContent = String(Math.round(temp)) + "°C";
            pEl.textContent = p.toFixed(2) + " MPa";
            rEl.textContent = rad.toFixed(2) + " mSv/h";
            sgEl.textContent = String(sg) + " / 3";

            var coreIntensity = (temp - 260) / 900;
            if (coreIntensity < 0) coreIntensity = 0;
            if (coreIntensity > 1) coreIntensity = 1;
            var glow = 12 + 26 * coreIntensity;
            var alpha = 0.4 + 0.5 * coreIntensity;
            coreDot.style.boxShadow = "0 0 " + glow + "px rgba(191,249,168," + alpha + ")";

            ts.style.color = temp > 950 ? "#f97316" : (temp > 650 ? "#eab308" : "#22c55e");
            ts.textContent = temp > 950 ? "Critical overheating (sim)" :
                             temp > 650 ? "Approaching redline (sim)" :
                             "Nominal";

            ps.style.color = p > 5.5 ? "#f97316" : (p > 3.2 ? "#eab308" : "#22c55e");
            ps.textContent = p > 5.5 ? "Containment strain (sim)" :
                             p > 3.2 ? "Elevated coupling (sim)" :
                             "Stable";

            rs.style.color = rad > 3 ? "#f97316" : (rad > 0.7 ? "#eab308" : "#22c55e");
            rs.textContent = rad > 3 ? "Severe release (sim)" :
                             rad > 0.7 ? "Leak indicated (sim)" :
                             "Shielding effective";
          }

          // ---------- Tick ----------
          function tick() {
            var coreBias = parseInt(leverCore.value,10) / 100;
            var coolBias = parseInt(leverCool.value,10) / 100;

            if (!meltdown) {
              var j = Math.random() - 0.5;
              temp += j * 3.5 + (coreBias - 0.8) * 4 - (coolBias - 1.0) * 3;
              p    += j * 0.06 + (temp - 300) / 2600;
              rad  += j * 0.018 + Math.max(0, (temp - 400)) / 6000;

              if (temp > 1200 && sg > 0) {
                sg -= 1;
                temp -= 260;
                p -= 0.7;
                rad -= 0.2;
                log("AUTO-SAFEGUARD (sim): staged insertion + coolant surge.");
              }

              if (temp > 1350 && p > 5.4 && sg === 0) {
                meltdown = true;
                log("!!! MELTDOWN SIM: Visuals + alarms only.");
                startSiren();
              }
            } else {
              temp += 36;
              p = Math.max(0.4, p - 0.25);
              rad += 0.9;
            }

            if (temp < 260) temp = 260;
            if (p < 0.9) p = 0.9;
            if (rad < 0.05) rad = 0.05;

            pushHist(histTemp, temp);
            pushHist(histPress, p);
            pushHist(histRad, rad);

            render();
            renderGraphs();
          }

          // ---------- Ops ----------
          function scram() {
            log("OP: SCRAM (sim)");
            temp -= 340;
            p -= 1.0;
            rad -= 0.3;
            if (temp < 260) temp = 260;
            render();
          }

          function relief() {
            log("OP: Relief valves (sim)");
            p -= 0.6;
            if (p < 0.9) p = 0.9;
            render();
          }

          function stress() {
            log("OP: Stress pulse (sim)");
            temp += 260;
            p += 1.4;
            rad += 0.45;
            render();
          }

          function chaos() {
            log("OP: Forced safeguard bypass (sim)");
            sg = 0;
            temp = 1250;
            p = 5.3;
            rad = 1.6;
            render();
          }

          function resetSim() {
            temp = 312;
            p = 1.3;
            rad = 0.14;
            sg = 3;
            meltdown = false;
            histTemp = [];
            histPress = [];
            histRad = [];
            stopSiren();
            log("Simulation reset to nominal baseline.");
            render();
          }

          btnScram.onclick = scram;
          btnRelief.onclick = relief;
          btnStress.onclick = stress;
          btnChaos.onclick = chaos;
          btnReset.onclick = resetSim;

          // ---------- Diagnostics ----------
          diagToggle.addEventListener("click", function(){
            diagnostics = !diagnostics;
            diagCard.style.display = diagnostics ? "block" : "none";
            diagBadge.textContent = "DIAGNOSTICS: " + (diagnostics ? "ON" : "OFF");
            if (diagnostics) diagCard.classList.add("diag-active");
            else diagCard.classList.remove("diag-active");
          });

          // ---------- Terminal ----------
          function runCmd(raw) {
            var cmd = String(raw || "").trim();
            if (!cmd) return;
            log("> " + cmd);
            var lower = cmd.toLowerCase();

            if (lower === "help") {
              log("commands: help, status, log <msg>, power <n>, coolant <n>, scram, relief, stress, chaos, reset, diag on/off, audio on/off, save-log");
              return;
            }
            if (lower === "status") {
              log("status: temp=" + Math.round(temp) + "C, p=" + p.toFixed(2) + "MPa, rad=" + rad.toFixed(2) + "mSv/h, sg=" + sg);
              return;
            }
            if (lower.indexOf("log ") === 0) {
              log(cmd.slice(4));
              return;
            }
            if (lower.indexOf("power ") === 0) {
              var n1 = parseInt(lower.split(/\s+/)[1]);
              if (!isNaN(n1)) {
                if (n1 < 40) n1 = 40;
                if (n1 > 120) n1 = 120;
                leverCore.value = String(n1);
                log("core drive set via terminal");
              }
              return;
            }
            if (lower.indexOf("coolant ") === 0) {
              var n2 = parseInt(lower.split(/\s+/)[1]);
              if (!isNaN(n2)) {
                if (n2 < 80) n2 = 80;
                if (n2 > 140) n2 = 140;
                leverCool.value = String(n2);
                log("coolant bias set via terminal");
              }
              return;
            }
            if (lower === "scram") { scram(); return; }
            if (lower === "relief") { relief(); return; }
            if (lower === "stress") { stress(); return; }
            if (lower === "chaos") { chaos(); return; }
            if (lower === "reset") { resetSim(); return; }
            if (lower === "diag on") {
              if (!diagnostics) diagToggle.click();
              return;
            }
            if (lower === "diag off") {
              if (diagnostics) diagToggle.click();
              return;
            }
            if (lower === "audio on") { setAudioOn(true); return; }
            if (lower === "audio off") { setAudioOn(false); return; }
            if (lower === "save-log") {
              maybePersist("[manual flush]\n");
              log("log flush requested");
              return;
            }

            log("unknown command — try `help`");
          }

          termRun.addEventListener("click", function(){
            runCmd(termInput.value);
            termInput.value = "";
          });

          termInput.addEventListener("keydown", function(e){
            if (e.key === "Enter") {
              runCmd(termInput.value);
              termInput.value = "";
            }
          });

          // ---------- Init ----------
          updatePersistBadge();
          resetSim();
          setInterval(tick, 900);
          setInterval(updatePersistBadge, 2000);
        </script>
      </body>
      </html>
    '';

  in {
    nixosConfigurations.chernos-iso = lib.nixosSystem {
      inherit system;
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
        ({ pkgs, lib, ... }: {
          isoImage.isoName = "chernos-os.iso";

          # ---------- Boot stack ----------
          boot.loader.grub.enable = lib.mkForce true;
          boot.loader.grub.version = 2;
          boot.loader.grub.device = "nodev";
          boot.loader.grub.theme = "${grubTheme}/share/grub/themes/chernos/theme.txt";

          boot.plymouth.enable = true;
          boot.plymouth.themePackages = [ plymouthTheme ];
          boot.plymouth.theme = "chernos";
          boot.kernelParams = [
            "quiet"
            "splash"
            "vt.global_cursor_default=0"
            "panic=10"
            "sysrq=0"
          ];

          # ---------- Silence noisy services ----------
          services.logrotate.enable = false;
          systemd.services."logrotate-checkconf".enable = false;
          systemd.services."systemd-journal-catalog-update".enable = false;
          systemd.services."systemd-update-done".enable = false;

          # ---------- Networking / SSH off ----------
          networking.useDHCP = false;
          networking.networkmanager.enable = false;
          systemd.services."systemd-networkd".enable = false;
          systemd.services."systemd-resolved".enable = false;
          systemd.services."sshd".enable = false;

          # ---------- Rendering (smooth pointer) ----------
          hardware.opengl.enable = true;
          environment.variables = {
            WLR_RENDERER_ALLOW_SOFTWARE = "1";
            WLR_NO_HARDWARE_CURSORS = "1";
          };

          services.xserver.enable = false;
          programs.sway.enable = true;

          # ---------- kiosk user ----------
          users.users.kiosk = {
            isNormalUser = true;
            password = "kiosk";
            extraGroups = [ "video" "input" ];
          };

          # ---------- Optional persistence service ----------
          systemd.services.chernos-persist = {
            wantedBy = [ "multi-user.target" ];
            after = [ "local-fs.target" "systemd-udev-settle.service" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${mountHelper}/bin/chernos-persist-helper";
              RemainAfterExit = true;
            };
          };

          systemd.tmpfiles.rules = [
            "d /persist 0755 root root -"
          ];

          # ---------- greetd → sway → chromium kiosk ----------
          services.greetd.enable = true;
          services.greetd.settings = {
            terminal.vt = 1;
            default_session = {
              command = "${pkgs.sway}/bin/sway";
              user = "kiosk";
            };
          };

          # disable extra TTYs
          systemd.services."getty@tty2".enable = false;
          systemd.services."getty@tty3".enable = false;
          systemd.services."getty@tty4".enable = false;
          systemd.services."getty@tty5".enable = false;
          systemd.services."getty@tty6".enable = false;

          environment.systemPackages = with pkgs; [
            chromium
            swaybg
            vim
          ];

          # sway config: pass ?persist=1 if CHERNOS_PERSIST was set by helper
          environment.etc."sway/config".text = ''
            set $mod Mod4

            # prevent exiting
            bindsym $mod+Shift+e exec echo "exit blocked"

            exec sh -lc '
              if [ -f /run/chernos-persist.env ]; then
                . /run/chernos-persist.env
              fi

              URL="file://${chernosPage}"
              if [ "x$CHERNOS_PERSIST" = "x1" ]; then
                URL="$URL?persist=1"
              fi

              ${pkgs.chromium}/bin/chromium \
                --enable-features=UseOzonePlatform \
                --ozone-platform=wayland \
                --kiosk "$URL" \
                --incognito \
                --start-fullscreen \
                --noerrdialogs \
                --disable-translate \
                --overscroll-history-navigation=0
            '
          '';
        })
      ];
    };

    packages.${system}.iso =
      self.nixosConfigurations.chernos-iso.config.system.build.isoImage;
  };
}
