{
  description = "ChernOS — NixOS-based nuclear-styled kiosk ISO (fictional reactor UI)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
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
          body { background:#07110a; color:#cfeecb; font-family:system-ui,sans-serif; }
          .wrap { min-height:100vh; padding:32px; display:flex; flex-direction:column; gap:16px; }
          .card { border-radius:16px; border:1px solid rgba(191,249,168,.16); background:rgba(0,0,0,.35); padding:16px 20px; }
          .label { font-size:10px; text-transform:uppercase; letter-spacing:1px; color:#9ca3af; }
          .big { font-size:24px; font-weight:600; color:#bff9a8; }
          .grid { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:10px; }
          .pill { font-size:9px; padding:3px 8px; border-radius:999px; border:1px solid rgba(191,249,168,.22); color:#9ca3af; }
          .btn { padding:5px 9px; border-radius:6px; border:1px solid rgba(191,249,168,.25); font-size:10px; color:#bff9a8; background:transparent; cursor:pointer; }
          .btn:hover { background:rgba(191,249,168,.06); }
          #log { max-height:170px; overflow:auto; }
        </style>
      </head>
      <body>
        <div class="wrap">
          <div class="card">
            <div class="label">SYSTEM ONLINE</div>
            <div class="big">ChernOS Ultra — Reactor Simulation Console</div>
            <div style="font-size:11px;color:#9ca3af;margin-top:4px;">
              Fictional nuclear control OS. Visual & logic simulation only. No real reactor control.
            </div>
          </div>

          <div class="grid">
            <div class="card">
              <div class="label">CORE TEMP</div>
              <div id="temp" class="big">312°C</div>
              <div id="temp-status" style="font-size:10px;margin-top:2px;">Nominal thermal profile</div>
            </div>
            <div class="card">
              <div class="label">PRESSURE</div>
              <div id="pressure" class="big">1.30 MPa</div>
              <div id="pressure-status" style="font-size:10px;margin-top:2px;">Within vessel limits</div>
            </div>
            <div class="card">
              <div class="label">RADIATION</div>
              <div id="rad" class="big">0.14 mSv/h</div>
              <div id="rad-status" style="font-size:10px;margin-top:2px;">Shielding effective</div>
            </div>
            <div class="card">
              <div class="label">SAFEGUARDS</div>
              <div id="sg" class="big">3 / 3</div>
              <div style="display:flex;flex-wrap:wrap;gap:4px;margin-top:4px;">
                <div class="pill">Primary SCRAM</div>
                <div class="pill">Coolant inject</div>
                <div class="pill">Containment seal</div>
              </div>
            </div>
          </div>

          <div class="card">
            <div class="label">OPERATOR ACTIONS</div>
            <div style="display:flex;flex-wrap:wrap;gap:6px;margin-top:4px;">
              <button class="btn" onclick="scram()">SCRAM CORE</button>
              <button class="btn" onclick="vent()">Open Relief</button>
              <button class="btn" onclick="stress()">Run Stress Test</button>
              <button class="btn" onclick="resetSim()">Reset Simulation</button>
              <button class="btn" onclick="maxChaos()">Force Failure (Sim)</button>
            </div>
            <div id="log" style="margin-top:6px;font-size:10px;color:#9ca3af;line-height:1.4;"></div>
          </div>
        </div>

        <script>
          const logEl = document.getElementById('log');
          const tempEl = document.getElementById('temp');
          const pEl = document.getElementById('pressure');
          const rEl = document.getElementById('rad');
          const sgEl = document.getElementById('sg');
          const ts = document.getElementById('temp-status');
          const ps = document.getElementById('pressure-status');
          const rs = document.getElementById('rad-status');

          let temp, p, rad, sg, meltdown;

          function l(msg){
            const t = new Date().toISOString().slice(11,19);
            const line = `[${t}] ${msg}`;
            const el = document.createElement('div');
            el.textContent = line;
            logEl.prepend(el);
          }

          function render(){
            tempEl.textContent = Math.round(temp) + "°C";
            pEl.textContent = p.toFixed(2) + " MPa";
            rEl.textContent = rad.toFixed(2) + " mSv/h";
            sgEl.textContent = sg + " / 3";

            ts.style.color = temp > 900 ? "#f97316" : temp > 600 ? "#eab308" : "#22c55e";
            ts.textContent = temp > 900 ? "Critical overheating (simulation)" :
                             temp > 600 ? "Approaching redline (simulation)" :
                             "Nominal thermal profile";

            ps.style.color = p > 5 ? "#f97316" : p > 3 ? "#eab308" : "#22c55e";
            ps.textContent = p > 5 ? "Containment strain (simulation)" :
                             p > 3 ? "Elevated vessel pressure (simulation)" :
                             "Within vessel limits";

            rs.style.color = rad > 3 ? "#f97316" : rad > 0.6 ? "#eab308" : "#22c55e";
            rs.textContent = rad > 3 ? "Severe release (simulation)" :
                             rad > 0.6 ? "Leak indicated (simulation)" :
                             "Shielding effective";
          }

          function tick(){
            if(!meltdown){
              temp += (Math.random()-0.5)*4;
              p += (Math.random()-0.5)*0.06;
              rad += (Math.random()-0.5)*0.02;

              if(temp > 950 && sg > 0){
                sg--;
                temp -= 220;
                p -= 0.8;
                rad -= 0.3;
                l("AUTO-SAFEGUARD DEPLOYED (sim) — rods insert + coolant inject.");
              }

              if(temp > 1300 && p > 5.5 && sg === 0){
                meltdown = true;
                l("!!! CORE DESTRUCTION (SIMULATION ONLY) — visual chaos mode.");
              }
            } else {
              temp += 40;
              p = Math.max(0.6, p - 0.25);
              rad += 0.9;
            }

            if(temp < 250) temp = 250;
            if(p < 0.9) p = 0.9;
            if(rad < 0.05) rad = 0.05;

            render();
          }

          function scram(){
            l("OPERATOR: SCRAM executed (sim). Core shutdown sequence.");
            temp -= 300;
            p -= 0.9;
            rad -= 0.2;
            if(temp < 260) temp = 260;
            render();
          }

          function vent(){
            l("OPERATOR: Relief paths opened (sim).");
            p -= 0.5;
            if(p < 0.9) p = 0.9;
            render();
          }

          function stress(){
            l("OPERATOR: Stress test initiated (sim).");
            temp += 260;
            p += 1.4;
            rad += 0.4;
            render();
          }

          function maxChaos(){
            l("!!! OPERATOR: Forced safeguard bypass (sim). Engaging failure scenario.");
            sg = 0;
            temp = 1200;
            p = 5.2;
            rad = 1.4;
            render();
          }

          function resetSim(){
            temp = 312;
            p = 1.3;
            rad = 0.14;
            sg = 3;
            meltdown = false;
            l("Simulation reset to nominal baseline.");
            render();
          }

          resetSim();
          setInterval(tick, 900);
        </script>
      </body>
      </html>
    '';
  in {
    nixosConfigurations.chernos-iso = pkgs.nixosSystem {
      system = system;
      modules = [
        ({ pkgs, ... }: {
          boot.loader.grub.enable = true;
          boot.loader.grub.version = 2;
          boot.loader.grub.device = "nodev";
          isoImage.isoName = "chernos-os.iso";

          services.xserver.enable = false;
          programs.sway.enable = true;

          users.users.kiosk = {
            isNormalUser = true;
            password = "kiosk";
          };

          services.getty.autologinUser = "kiosk";

          environment.systemPackages = with pkgs; [
            chromium
            swaybg
            vim
          ];

          # Auto-start sway on TTY1
          environment.loginShellInit = ''
            if [ "$(tty)" = "/dev/tty1" ]; then
              exec sway
            fi
          '';

          # Sway config: kiosk Chromium with ChernOS UI
          environment.etc."sway/config".text = ''
            include /etc/sway/config.d/*

            bindsym $mod+Shift+e exec echo "exit blocked"
            bindsym Ctrl+Alt+BackSpace exec echo "blocked"
            bindsym Ctrl+Alt+Delete exec echo "blocked"

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

    # So you can run: nix build .#iso
    packages.${system}.iso =
      self.nixosConfigurations.chernos-iso.config.system.build.isoImage;
  };
}
