{
  description = "ChernOS v1.2.0 — Ultra+ nuclear-themed kiosk OS (fictional reactor UI)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    lib = nixpkgs.lib;
    pkgs = import nixpkgs { inherit system; };

    # ---------- GRUB THEME (black + neon green) ----------
    grubTheme = pkgs.runCommand "grub-theme-chernos" {} ''
      mkdir -p $out/share/grub/themes/chernos
      cat > $out/share/grub/themes/chernos/theme.txt <<EOF
terminal_output gfxterm
color_normal cfeecb 000000
color_highlight bff9a8 000000

if ! background_image /@theme_background@; then
  insmod gfxterm
fi

+ boot_menu {
  left = 10%
  top = 30%
  width = 80%
  height = 40%
  item_color = "cfeecb"
  selected_item_color = "bff9a8"
  selected_item_pixmap_style = "highlight"
}
EOF
    '';

    # ---------- PLYMOUTH THEME (nuclear glow) ----------
    plymouthTheme = pkgs.runCommand "plymouth-theme-chernos" {} ''
      mkdir -p $out/share/plymouth/themes/chernos

      cat > $out/share/plymouth/themes/chernos/chernos.plymouth <<EOF
[Plymouth Theme]
Name=ChernOS Ultra+
Description=Nuclear green boot glow
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/chernos
ScriptFile=/usr/share/plymouth/themes/chernos/chernos.script
EOF

      cat > $out/share/plymouth/themes/chernos/chernos.script <<'EOF'
Window.SetBackgroundTopColor (0.0, 0.02, 0.01);
Window.SetBackgroundBottomColor (0.0, 0.0, 0.0);
# Minimal themed splash.
EOF
    '';

    # ---------- FULL CHERNOS ULTRA+ UI (HTML + JS) ----------
    chernosPage = pkgs.writeText "index.html" ''
      <!doctype html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
        <title>ChernOS Ultra+ v1.2.0</title>
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
            font-family: system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
            overflow: hidden;
          }
          .wrap {
            min-height: 100vh;
            padding: 22px 30px;
            display: flex;
            flex-direction: column;
            gap: 14px;
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
            0% { opacity: 0.35; filter: blur(0px); }
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
          #log {
            max-height: 190px;
            overflow: auto;
            font-size: 10px;
          }
          .toolbar {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
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
            0%, 82%, 100% { opacity: 0; }
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
          .lever { width: 120px; }
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
          <!-- Top toolbar -->
          <div class="card toolbar">
            <div class="toolbar-left">
              <div class="label">CHERNOS ULTRA+ v1.2.0</div>
              <div class="big">Reactor Simulation Control Deck</div>
              <div class="sub">Fictional environment. No real hardware. All telemetry & events are simulated.</div>
              <div class="status-board">
                <div class="status-cell">CORE CHANNELS: SYNCED</div>
                <div class="status-cell">COOLANT LOOP: NOMINAL</div>
                <div class="status-cell">CONTAINMENT GRID: STABLE</div>
                <div class="status-cell">I/O BUS: GREEN</div>
                <div class="status-cell">SENSOR MESH: ONLINE</div>
                <div class="status-cell">ALERT QUEUE: IDLE</div>
              </div>
            </div>
            <div style="display:flex; flex-direction:column; gap:5px; align-items:flex-end;">
              <div style="display:flex; gap:6px; align-items:center;">
                <span class="badge">SIM-CORE ONLINE</span>
                <span class="badge" id="diag-badge">DIAGNOSTICS: OFF</span>
              </div>
              <div style="display:flex; gap:10px; align-items:center;">
                <div class="core-ring-wrap">
                  <div class="core-ring"></div>
                  <div class="core-ring inner"></div>
                  <div class="core-dot" id="core-dot"></div>
                </div>
                <div style="display:flex; flex-direction:column; gap:4px; align-items:flex-end;">
                  <button class="btn" id="diag-toggle">Diagnostics Mode</button>
                  <button class="btn" id="mute-toggle">Toggle Hum / Alarms</button>
                  <span class="mute-indicator" id="mute-state">Audio: ON</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Main telemetry row -->
          <div class="grid-4">
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
              <div style="margin-top:6px; display:flex; gap:8px;">
                <div class="lever-wrap">
                  <span>Core Drive Lever</span>
                  <input id="lever-core" class="lever" type="range" min="40" max="120" value="80">
                </div>
                <div class="lever-wrap">
                  <span>Coolant Bias</span>
                  <input id="lever-coolant" class="lever" type="range" min="80" max="140" value="100">
                </div>
              </div>
            </div>
          </div>

          <!-- Controls + log -->
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

          <!-- Diagnostics graphs -->
          <div class="card" id="diag-card" style="display:none;">
            <div class="label">DIAGNOSTICS MODE — TELEMETRY GRAPHS</div>
            <div class="sub">Simulated traces: core temperature, pressure coupling, radiation flux.</div>
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
          var logEl = document.getElementById('log');
          var tempEl = document.getElementById('temp');
          var pEl = document.getElementById('pressure');
          var rEl = document.getElementById('rad');
          var sgEl = document.getElementById('sg');
          var ts = document.getElementById('temp-status');
          var ps = document.getElementById('pressure-status');
          var rs = document.getElementById('rad-status');
          var diagToggle = document.getElementById('diag-toggle');
          var diagBadge = document.getElementById('diag-badge');
          var diagCard = document.getElementById('diag-card');
          var muteToggle = document.getElementById('mute-toggle');
          var muteState = document.getElementById('mute-state');
          var coreDot = document.getElementById('core-dot');

          var btnScram = document.getElementById('btn-scram');
          var btnRelief = document.getElementById('btn-relief');
          var btnStress = document.getElementById('btn-stress');
          var btnChaos = document.getElementById('btn-chaos');
          var btnReset = document.getElementById('btn-reset');

          var leverCore = document.getElementById('lever-core');
          var leverCool = document.getElementById('lever-coolant');

          var temp, p, rad, sg, meltdown;
          var diagnostics = false;

          var histLen = 80;
          var histTemp = [];
          var histPress = [];
          var histRad = [];

          var audioCtx = null;
          var humNode = null;
          var alarmNode = null;
          var audioOn = true;

          function ensureAudio(){
            if(audioCtx === null){
              try {
                audioCtx = new (window.AudioContext || window.webkitAudioContext)();
              } catch(e) {
                audioCtx = null;
              }
            }
          }

          function startHum(){
            if(!audioOn) return;
            ensureAudio();
            if(!audioCtx || humNode) return;
            try {
              var osc = audioCtx.createOscillator();
              var gain = audioCtx.createGain();
              osc.type = "sine";
              osc.frequency.value = 52;
              gain.gain.value = 0.035;
              osc.connect(gain);
              gain.connect(audioCtx.destination);
              osc.start();
              humNode = { osc: osc, gain: gain };
            } catch(e){}
          }

          function stopHum(){
            if(humNode){
              try { humNode.osc.stop(); } catch(e){}
              humNode = null;
            }
          }

          function startAlarm(){
            if(!audioOn) return;
            ensureAudio();
            if(!audioCtx || alarmNode) return;
            try {
              var osc = audioCtx.createOscillator();
              var gain = audioCtx.createGain();
              osc.type = "square";
              osc.frequency.value = 680;
              gain.gain.value = 0.0;
              osc.connect(gain);
              gain.connect(audioCtx.destination);
              osc.start();

              var on = false;
              var interval = setInterval(function(){
                if(!audioOn){
                  gain.gain.value = 0;
                  return;
                }
                on = !on;
                gain.gain.value = on ? 0.06 : 0.0;
              }, 260);

              alarmNode = { osc: osc, gain: gain, interval: interval };
            } catch(e){}
          }

          function stopAlarm(){
            if(alarmNode){
              clearInterval(alarmNode.interval);
              try { alarmNode.osc.stop(); } catch(e){}
              alarmNode = null;
            }
          }

          muteToggle.addEventListener("click", function(){
            audioOn = !audioOn;
            if(audioOn){
              startHum();
              if(meltdown) startAlarm();
              muteState.textContent = "Audio: ON";
            } else {
              stopHum();
              stopAlarm();
              muteState.textContent = "Audio: OFF";
            }
          });

          window.addEventListener("load", function(){
            setTimeout(startHum, 400);
          });

          function log(msg){
            var t = new Date().toISOString().slice(11,19);
            var el = document.createElement('div');
            el.textContent = "[" + t + "] " + msg;
            logEl.prepend(el);
          }

          function pushHist(buf, value){
            buf.push(value);
            if(buf.length > histLen) buf.shift();
          }

          function drawGraph(id, data, color){
            var c = document.getElementById(id);
            if(!c) return;
            var ctx = c.getContext('2d');
            var w = c.width;
            var h = c.height;
            ctx.clearRect(0,0,w,h);
            if(data.length < 2) return;

            var min = Math.min.apply(null, data);
            var max = Math.max.apply(null, data);
            var span = (max - min) || 1;

            ctx.beginPath();
            ctx.strokeStyle = color;
            ctx.lineWidth = 1;

            for(var i=0;i<data.length;i++){
              var v = data[i];
              var x = (i / (data.length - 1)) * (w - 4) + 2;
              var y = h - 4 - ((v - min)/span) * (h - 8);
              if(i === 0) ctx.moveTo(x,y);
              else ctx.lineTo(x,y);
            }
            ctx.stroke();
          }

          function renderDiagnostics(){
            if(!diagnostics) return;
            drawGraph("diag-core", histTemp, "#bff9a8");
            drawGraph("diag-press", histPress, "#86efac");
            drawGraph("diag-rad", histRad, "#22c55e");
          }

          function render(){
            tempEl.textContent = Math.round(temp) + "°C";
            pEl.textContent = p.toFixed(2) + " MPa";
            rEl.textContent = rad.toFixed(2) + " mSv/h";
            sgEl.textContent = sg + " / 3";

            var coreIntensity = (temp - 260) / 900;
            if(coreIntensity < 0) coreIntensity = 0;
            if(coreIntensity > 1) coreIntensity = 1;
            var glow = 12 + 26 * coreIntensity;
            var alpha = 0.4 + 0.5 * coreIntensity;
            coreDot.style.boxShadow = "0 0 " + glow + "px rgba(191,249,168," + alpha + ")";

            ts.style.color = temp > 950 ? "#f97316" : (temp > 650 ? "#eab308" : "#22c55e");
            ts.textContent =
              temp > 950 ? "Critical overheating (sim)" :
              temp > 650 ? "Approaching redline (sim)" :
              "Nominal";

            ps.style.color = p > 5.5 ? "#f97316" : (p > 3.2 ? "#eab308" : "#22c55e");
            ps.textContent =
              p > 5.5 ? "Containment strain (sim)" :
              p > 3.2 ? "Elevated coupling (sim)" :
              "Stable containment";

            rs.style.color = rad > 3 ? "#f97316" : (rad > 0.7 ? "#eab308" : "#22c55e");
            rs.textContent =
              rad > 3 ? "Severe release (sim)" :
              rad > 0.7 ? "Leak indicated (sim)" :
              "Shielding effective";
          }

          function tick(){
            var coreBias = parseInt(leverCore.value,10) / 100;
            var coolBias = parseInt(leverCool.value,10) / 100;

            if(!meltdown){
              var j = (Math.random() - 0.5);
              temp += j * 3.5 + (coreBias - 0.8) * 4 - (coolBias - 1.0) * 3;
              p += j * 0.06 + (temp - 300)/2600;
              rad += j * 0.018 + Math.max(0, (temp - 400))/6000;

              if(temp > 1200 && sg > 0){
                sg -= 1;
                temp -= 260;
                p -= 0.7;
                rad -= 0.2;
                log("AUTO-SAFEGUARD (sim): staged insertion and coolant surge.");
              }

              if(temp > 1350 && p > 5.4 && sg === 0){
                meltdown = true;
                log("!!! SIMULATED CORE DISASSEMBLY — meltdown visuals & alarms only.");
                startAlarm();
              }
            } else {
              temp += 36;
              p = Math.max(0.4, p - 0.25);
              rad += 0.9;
            }

            if(temp < 260) temp = 260;
            if(p < 0.9) p = 0.9;
            if(rad < 0.05) rad = 0.05;

            pushHist(histTemp, temp);
            pushHist(histPress, p);
            pushHist(histRad, rad);

            render();
            renderDiagnostics();
          }

          function scram(){
            log("OPERATOR: SCRAM command (sim).");
            temp -= 340;
            p -= 1.0;
            rad -= 0.3;
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
            rad += 0.45;
            render();
          }

          function maxChaos(){
            log("!!! OPERATOR: Forced safeguard bypass (sim).");
            sg = 0;
            temp = 1250;
            p = 5.3;
            rad = 1.6;
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
            stopAlarm();
            log("Simulation reset to nominal baseline.");
            render();
          }

          btnScram.onclick = scram;
          btnRelief.onclick = relief;
          btnStress.onclick = stress;
          btnChaos.onclick = maxChaos;
          btnReset.onclick = resetSim;

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

          # Boot stack
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

          # Quiet / no useless network stuff
          networking.useDHCP = false;
          networking.networkmanager.enable = false;
          systemd.services."systemd-networkd".enable = false;
          systemd.services."systemd-resolved".enable = false;
          systemd.services."sshd".enable = false;

          # Renderer hints for VMs (less EGL/vmwgfx whining)
          hardware.opengl.enable = true;
          environment.variables = {
            WLR_RENDERER_ALLOW_SOFTWARE = "1";
            WLR_NO_HARDWARE_CURSORS = "1";
            LIBGL_ALWAYS_SOFTWARE = "1";
          };

          services.xserver.enable = false;
          programs.sway.enable = true;

          # kiosk user
          users.users.kiosk = {
            isNormalUser = true;
            password = "kiosk";
            extraGroups = [ "video" "input" ];
          };

          # greetd → sway kiosk (fixed config; no 'likely broken' msg)
          services.greetd.enable = true;
          services.greetd.settings = {
            terminal.vt = 1;
            default_session = {
              command = "${pkgs.sway}/bin/sway";
              user = "kiosk";
            };
          };

          # kill extra TTYs
          systemd.services."getty@tty2".enable = false;
          systemd.services."getty@tty3".enable = false;
          systemd.services."getty@tty4".enable = false;
          systemd.services."getty@tty5".enable = false;
          systemd.services."getty@tty6".enable = false;

          environment.systemPackages = with pkgs; [
            chromium
            swaybg
            vim
            calamares
          ];

          # sway config for kiosk
          environment.etc."sway/config".text = ''
            set $mod Mod4

            # DO NOT include non-existent directories to avoid warnings
            # include /etc/sway/config.d/*

            # prevent exiting
            bindsym $mod+Shift+e exec echo "exit blocked"

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

          # optional persistence
          fileSystems."/persist" = {
            device = "/dev/disk/by-label/CHERNOS_PERSIST";
            fsType = "ext4";
            options = [ "nofail" "x-systemd.device-timeout=1s" ];
          };
          fileSystems."/home" = {
            device = "/persist/home";
            fsType = "none";
            options = [ "bind" "nofail" ];
          };
          fileSystems."/var" = {
            device = "/persist/var";
            fsType = "none";
            options = [ "bind" "nofail" ];
          };
          systemd.tmpfiles.rules = [
            "d /persist 0755 root root -"
            "d /persist/home 0755 root root -"
            "d /persist/var 0755 root root -"
          ];
        })
      ];
    };

    packages.${system}.iso =
      self.nixosConfigurations.chernos-iso.config.system.build.isoImage;
  };
}
