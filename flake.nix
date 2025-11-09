{
  description = "ChernOS v1.1.0 — NixOS-based nuclear-themed kiosk OS with glow, hum & diagnostics (fictional reactor UI)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    pkgs = import nixpkgs { inherit system; };

    chernosPage = pkgs.writeText "index.html" ''
      <!doctype html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <title>ChernOS Ultra</title>
        <meta name="viewport" content="width=device-width,initial-scale=1">
        <script src="https://cdn.tailwindcss.com"></script>
        <style>
          :root {
            --nuclear-green: #bff9a8;
            --nuclear-soft: rgba(191,249,168,0.18);
          }
          body {
            margin: 0;
            background: radial-gradient(circle at 20% 0%, rgba(0,255,140,0.07), transparent 60%) #020806;
            color: #cfeecb;
            font-family: system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
            overflow: hidden;
          }
          .wrap {
            min-height: 100vh;
            padding: 24px 32px;
            display: flex;
            flex-direction: column;
            gap: 16px;
            position: relative;
          }
          .reactor-glow {
            position: fixed;
            inset: -40px;
            pointer-events: none;
            background:
              radial-gradient(circle at 12% 0%, rgba(0,255,140,0.04), transparent 60%),
              radial-gradient(circle at 88% 0%, rgba(0,255,140,0.02), transparent 55%);
            mix-blend-mode: screen;
            opacity: 0.9;
            animation: glowPulse 4s ease-in-out infinite alternate;
          }
          @keyframes glowPulse {
            0% { opacity: 0.45; filter: blur(0px); }
            100% { opacity: 0.9; filter: blur(1px); }
          }
          .card {
            border-radius: 16px;
            border: 1px solid rgba(191,249,168,0.16);
            background: radial-gradient(circle at top, rgba(0,255,140,0.02), transparent 90%) rgba(0,0,0,0.40);
            padding: 14px 18px;
            backdrop-filter: blur(8px);
            box-shadow: 0 0 26px rgba(0,0,0,0.7);
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
          .grid {
            display: grid;
            grid-template-columns: repeat(4, minmax(0,1fr));
            gap: 10px;
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
            background: rgba(191,249,168,0.13);
            box-shadow: 0 0 12px rgba(191,249,168,0.16);
          }
          #log {
            max-height: 190px;
            overflow: auto;
            font-size: 10px;
          }
          .toolbar {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            align-items: center;
            justify-content: space-between;
          }
          .toolbar-left {
            display: flex;
            flex-direction: column;
            gap: 2px;
          }
          .sub {
            font-size: 11px;
            color: #9ca3af;
          }
          .badge {
            font-size: 9px;
            padding: 2px 7px;
            border-radius: 999px;
            border: 1px solid rgba(191,249,168,0.32);
            color: var(--nuclear-green);
          }
          .diag-wrapper {
            display: grid;
            grid-template-columns: repeat(3, minmax(0,1fr));
            gap: 8px;
            margin-top: 6px;
          }
          .diag-label {
            font-size: 9px;
            color: #9ca3af;
            margin-bottom: 2px;
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
          <div class="card toolbar">
            <div class="toolbar-left">
              <div class="label">CHERNOS ULTRA v1.1.0</div>
              <div class="big">Reactor Operations Simulation Deck</div>
              <div class="sub">Fictional nuclear control environment. All behavior simulated. No real-world control.</div>
            </div>
            <div style="display:flex; flex-direction:column; gap:4px; align-items:flex-end;">
              <div style="display:flex; gap:6px; align-items:center;">
                <span class="badge">SIM-CORE ONLINE</span>
                <span class="badge" id="diag-badge">DIAGNOSTICS: OFF</span>
              </div>
              <div style="display:flex; gap:6px; align-items:center;">
                <button class="btn" id="diag-toggle">Diagnostics Mode</button>
                <button class="btn" id="mute-toggle">Toggle Hum</button>
                <span class="mute-indicator" id="mute-state">Hum: ON</span>
              </div>
            </div>
          </div>

          <div class="grid">
            <div class="card">
              <div class="label">CORE TEMP</div>
              <div id="temp" class="big">312°C</div>
              <div id="temp-status" style="font-size:10px;margin-top:2px;">Nominal thermal profile</div>
            </div>
            <div class="card">
              <div class="label">PRESSURE COUPLING</div>
              <div id="pressure" class="big">1.30 MPa</div>
              <div id="pressure-status" style="font-size:10px;margin-top:2px;">Stable containment</div>
            </div>
            <div class="card">
              <div class="label">RADIATION FLUX</div>
              <div id="rad" class="big">0.14 mSv/h</div>
              <div id="rad-status" style="font-size:10px;margin-top:2px;">Shielding effective</div>
            </div>
            <div class="card">
              <div class="label">SAFEGUARDS</div>
              <div id="sg" class="big">3 / 3</div>
              <div style="display:flex;flex-wrap:wrap;gap:4px;margin-top:4px;">
                <div class="pill">Primary SCRAM</div>
                <div class="pill">Coolant Surge</div>
                <div class="pill">Containment Seal</div>
              </div>
            </div>
          </div>

          <div class="card">
            <div class="label">OPERATOR CONTROL SURFACE</div>
            <div style="display:flex;flex-wrap:wrap;gap:6px;margin-top:4px;">
              <button class="btn" id="btn-scram">SCRAM CORE</button>
              <button class="btn" id="btn-relief">Relief Valves</button>
              <button class="btn" id="btn-stress">Stress Pulse</button>
              <button class="btn" id="btn-chaos">Force Failure (Sim)</button>
              <button class="btn" id="btn-reset">Reset</button>
            </div>
            <div id="log" style="margin-top:6px;line-height:1.4;"></div>
          </div>

          <div class="card" id="diag-card" style="display:none;">
            <div class="label">DIAGNOSTICS MODE — TELEMETRY GRAPHS</div>
            <div class="sub">Simulated traces for core temperature, pressure coupling, and radiation flux.</div>
            <div class="diag-wrapper">
              <div>
                <div class="diag-label">Core Temp Trend</div>
                <canvas id="diag-core"></canvas>
              </div>
              <div>
                <div class="diag-label">Pressure Coupling Trend</div>
                <canvas id="diag-press"></canvas>
              </div>
              <div>
                <div class="diag-label">Radiation Flux Trend</div>
                <canvas id="diag-rad"></canvas>
              </div>
            </div>
          </div>
        </div>

        <script>
          // ------- DOM refs -------
          const logEl = document.getElementById('log');
          const tempEl = document.getElementById('temp');
          const pEl = document.getElementById('pressure');
          const rEl = document.getElementById('rad');
          const sgEl = document.getElementById('sg');
          const ts = document.getElementById('temp-status');
          const ps = document.getElementById('pressure-status');
          const rs = document.getElementById('rad-status');
          const diagToggle = document.getElementById('diag-toggle');
          const diagBadge = document.getElementById('diag-badge');
          const diagCard = document.getElementById('diag-card');
          const muteToggle = document.getElementById('mute-toggle');
          const muteState = document.getElementById('mute-state');

          const btnScram = document.getElementById('btn-scram');
          const btnRelief = document.getElementById('btn-relief');
          const btnStress = document.getElementById('btn-stress');
          const btnChaos = document.getElementById('btn-chaos');
          const btnReset = document.getElementById('btn-reset');

          // ------- Simulation state -------
          let temp, p, rad, sg, meltdown;
          let diagnostics = false;

          // History buffers for diagnostics graphs
          const histLen = 80;
          let histTemp = [];
          let histPress = [];
          let histRad = [];

          // ------- Logging -------
          function log(msg){
            const t = new Date().toISOString().slice(11,19);
            const line = "[" + t + "] " + msg;
            const el = document.createElement('div');
            el.textContent = line;
            logEl.prepend(el);
          }

          // ------- Render main telemetry -------
          function render(){
            tempEl.textContent = Math.round(temp) + "°C";
            pEl.textContent = p.toFixed(2) + " MPa";
            rEl.textContent = rad.toFixed(2) + " mSv/h";
            sgEl.textContent = sg + " / 3";

            ts.style.color = temp > 950 ? "#f97316" : temp > 650 ? "#eab308" : "#22c55e";
            ts.textContent =
              temp > 950 ? "Critical overheating (sim)" :
              temp > 650 ? "Approaching redline (sim)" :
              "Nominal";

            ps.style.color = p > 5.5 ? "#f97316" : p > 3.2 ? "#eab308" : "#22c55e";
            ps.textContent =
              p > 5.5 ? "Containment strain (sim)" :
              p > 3.2 ? "Elevated coupling (sim)" :
              "Stable containment";

            rs.style.color = rad > 3 ? "#f97316" : rad > 0.7 ? "#eab308" : "#22c55e";
            rs.textContent =
              rad > 3 ? "Severe release (sim)" :
              rad > 0.7 ? "Leak indicated (sim)" :
              "Shielding effective";
          }

          // ------- Diagnostics graphs -------
          function pushHist(buf, value){
            buf.push(value);
            if(buf.length > histLen) buf.shift();
          }

          function drawGraph(canvasId, data, colorHex){
            const c = document.getElementById(canvasId);
            if(!c) return;
            const ctx = c.getContext('2d');
            const w = c.width;
            const h = c.height;
            ctx.clearRect(0,0,w,h);

            if(data.length < 2) return;

            const min = Math.min.apply(null, data);
            const max = Math.max.apply(null, data);
            const span = (max - min) || 1;

            ctx.beginPath();
            ctx.strokeStyle = colorHex;
            ctx.lineWidth = 1;
            data.forEach(function(v, i){
              const x = (i / (data.length - 1)) * (w - 4) + 2;
              const y = h - 4 - ((v - min) / span) * (h - 8);
              if(i === 0) ctx.moveTo(x,y);
              else ctx.lineTo(x,y);
            });
            ctx.stroke();
          }

          function renderDiagnostics(){
            if(!diagnostics) return;
            drawGraph("diag-core", histTemp, "#bff9a8");
            drawGraph("diag-press", histPress, "#86efac");
            drawGraph("diag-rad", histRad, "#22c55e");
          }

          // ------- Simulation tick -------
          function tick(){
            if(!meltdown){
              const j = (Math.random() - 0.5);
              temp += j * 4;
              p += j * 0.08;
              rad += j * 0.02;

              if(temp > 1200 && sg > 0){
                sg -= 1;
                temp -= 260;
                p -= 0.7;
                rad -= 0.2;
                log("AUTO-SAFEGUARD (sim): rods insert, coolant surge.");
              }

              if(temp > 1350 && p > 5.4 && sg === 0){
                meltdown = true;
                log("!!! SIMULATED CORE DISASSEMBLY — failure mode visuals only.");
              }
            } else {
              temp += 40;
              p = Math.max(0.4, p - 0.3);
              rad += 1.0;
            }

            if(temp < 260) temp = 260;
            if(p < 0.9) p = 0.9;
            if(rad < 0.05) rad = 0.05;

            // push into history for diagnostics
            pushHist(histTemp, temp);
            pushHist(histPress, p);
            pushHist(histRad, rad);

            render();
            renderDiagnostics();
          }

          // ------- Controls -------
          function scram(){
            log("OPERATOR: SCRAM command (sim).");
            temp -= 320;
            p -= 0.9;
            rad -= 0.25;
            if(temp < 260) temp = 260;
            render();
          }

          function relief(){
            log("OPERATOR: Relief valves opened (sim).");
            p -= 0.6;
            if(p < 0.9) p = 0.9;
            render();
          }

          function stress(){
            log("OPERATOR: Transient stress pulse (sim).");
            temp += 260;
            p += 1.4;
            rad += 0.4;
            render();
          }

          function maxChaos(){
            log("!!! OPERATOR: Forced safeguard bypass (sim).");
            sg = 0;
            temp = 1250;
            p = 5.2;
            rad = 1.5;
            render();
          }

          function resetSim(){
            temp = 312;
            p = 1.3;
            rad = 0.14;
            sg = 3;
            meltdown = false;
            histTemp = [];
            histPress = [];
            histRad = [];
            log("Simulation reset to nominal baseline.");
            render();
          }

          // ------- Diagnostics toggle -------
          diagToggle.addEventListener("click", function(){
            diagnostics = !diagnostics;
            if(diagnostics){
              diagCard.style.display = "block";
              diagCard.classList.add("diag-active");
              diagBadge.textContent = "DIAGNOSTICS: ON";
              diagBadge.style.color = "#bbf7d0";
            } else {
              diagCard.style.display = "none";
              diagCard.classList.remove("diag-active");
              diagBadge.textContent = "DIAGNOSTICS: OFF";
              diagBadge.style.color = "#9ca3af";
            }
          });

          // ------- Hum / background sound (Web Audio) -------
          let audioCtx = null;
          let humNode = null;
          let humOn = true;

          function startHum(){
            try {
              if(audioCtx === null){
                audioCtx = new (window.AudioContext || window.webkitAudioContext)();
              }
              if(humNode) return;
              const osc = audioCtx.createOscillator();
              const gain = audioCtx.createGain();
              osc.type = "sine";
              osc.frequency.value = 52; // low reactor hum
              gain.gain.value = 0.04;   // subtle
              osc.connect(gain);
              gain.connect(audioCtx.destination);
              osc.start();
              humNode = { osc: osc, gain: gain };
            } catch(e){
              // ignore failures silently
            }
          }

          function stopHum(){
            if(humNode){
              try { humNode.osc.stop(); } catch(e){}
              humNode = null;
            }
          }

          function initHum(){
            if(humOn){
              startHum();
            }
          }

          muteToggle.addEventListener("click", function(){
            humOn = !humOn;
            if(humOn){
              startHum();
              muteState.textContent = "Hum: ON";
            } else {
              stopHum();
              muteState.textContent = "Hum: OFF";
            }
          });

          // Some browsers require interaction — attempt startup anyway
          window.addEventListener("load", function(){
            setTimeout(initHum, 400);
          });

          // ------- Wire buttons -------
          btnScram.onclick = scram;
          btnRelief.onclick = relief;
          btnStress.onclick = stress;
          btnChaos.onclick = maxChaos;
          btnReset.onclick = resetSim;

          // ------- Boot -------
          resetSim();
          setInterval(tick, 900);
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

          hardware.opengl = {
            enable = true;
            driSupport = true;
            driSupport32Bit = true;
          };

          environment.variables = {
            WLR_RENDERER_ALLOW_SOFTWARE = "1";
            WLR_NO_HARDWARE_CURSORS = "1";
          };

          services.xserver.enable = false;
          programs.sway.enable = true;

          users.users.kiosk = {
            isNormalUser = true;
            password = "kiosk";
            extraGroups = [ "video" "input" ];
          };

          services.greetd.enable = true;
          services.greetd.settings = {
            default_session = {
              command = "${pkgs.sway}/bin/sway";
              user = "kiosk";
            };
          };

          environment.systemPackages = with pkgs; [
            chromium
            swaybg
            vim
          ];

          environment.etc."sway/config".text = ''
            # Define mod key so binds are valid
            set $mod Mod4

            include /etc/sway/config.d/*

            # Optional: block a manual exit combo
            bindsym $mod+Shift+e exec echo "exit blocked"

            # Launch ChernOS UI in Chromium kiosk
            exec ${pkgs.chromium}/bin/chromium \
              --enable-features=UseOzonePlatform \
              --ozone-platform=wayland \
              --kiosk file://${chernosPage} \
              --incognito \
              --start-fullscreen \
              --noerrdialogs \
              --disable-translate \
              --overscroll-history-navigation=0
          '';
        })
      ];
    };

    packages.${system}.iso =
      self.nixosConfigurations.chernos-iso.config.system.build.isoImage;
  };
}
