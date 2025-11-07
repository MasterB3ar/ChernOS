{
  description = "ChernOS — stable NixOS-based nuclear-styled kiosk ISO (fictional reactor UI)";

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
          body { background:#020806; color:#cfeecb; font-family:system-ui,sans-serif; }
          .wrap { min-height:100vh; padding:32px; display:flex; flex-direction:column; gap:16px; }
          .card { border-radius:16px; border:1px solid rgba(191,249,168,.16); background:rgba(0,0,0,.38); padding:16px 20px; }
          .label { font-size:10px; text-transform:uppercase; letter-spacing:1px; color:#9ca3af; }
          .big { font-size:24px; font-weight:600; color:#bff9a8; }
          .grid { display:grid; grid-template-columns:repeat(4,minmax(0,1fr)); gap:10px; }
          .pill { font-size:9px; padding:3px 8px; border-radius:999px; border:1px solid rgba(191,249,168,.22); color:#9ca3af; }
          .btn { padding:5px 9px; border-radius:6px; border:1px solid rgba(191,249,168,.25); font-size:10px; color:#bff9a8; background:transparent; cursor:pointer; }
          .btn:hover { background:rgba(191,249,168,.10); }
          #log { max-height:190px; overflow:auto; font-size:10px; }
        </style>
      </head>
      <body>
        <div class="wrap">
          <div class="card">
            <div class="label">CHERNOS ULTRA</div>
            <div class="big">Reactor Operations Simulation Deck</div>
            <div style="font-size:11px;color:#9ca3af;margin-top:4px;">
              All behavior is simulated. This system does not control real hardware.
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
              <button class="btn" onclick="scram()">SCRAM CORE</button>
              <button class="btn" onclick="relief()">Relief Valves</button>
              <button class="btn" onclick="stress()">Stress Pulse</button>
              <button class="btn" onclick="maxChaos()">Force Failure (Sim)</button>
              <button class="btn" onclick="resetSim()">Reset</button>
            </div>
            <div id="log" style="margin-top:6px;line-height:1.4;"></div>
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

          function log(msg){
            const t = new Date().toISOString().slice(11,19);
            const line = "[" + t + "] " + msg;
            const el = document.createElement('div');
            el.textContent = line;
            logEl.prepend(el);
          }

          function render(){
            tempEl.textContent = Math.round(temp) + "°C";
            pEl.textContent = p.toFixed(2) + " MPa";
            rEl.textContent = rad.toFixed(2) + " mSv/h";
            sgEl.textContent = sg + " / 3";

            ts.style.color = temp > 950 ? "#f97316" : temp > 650 ? "#eab308" : "#22c55e";
            ts.textContent = temp > 950 ? "Critical overheating (sim)" :
                             temp > 650 ? "Approaching redline (sim)" :
                             "Nominal";

            ps.style.color = p > 5.5 ? "#f97316" : p > 3.2 ? "#eab308" : "#22c55e";
            ps.textContent = p > 5.5 ? "Containment strain (sim)" :
                             p > 3.2 ? "Elevated coupling (sim)" :
                             "Stable containment";

            rs.style.color = rad > 3 ? "#f97316" : rad > 0.7 ? "#eab308" : "#22c55e";
            rs.textContent = rad > 3 ? "Severe release (sim)" :
                             rad > 0.7 ? "Leak indicated (sim)" :
                             "Shielding effective";
          }

          function tick(){
            if(!meltdown){
              const j = (Math.random()-0.5);
              temp += j*4;
              p += j*0.08;
              rad += j*0.02;

              if(temp > 1200 && sg > 0){
                sg--;
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

            render();
          }

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
            log("Simulation reset to nominal baseline.");
            render();
          }

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
        # Base ISO module
        "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"

        ({ pkgs, lib, ... }: {
          # Use GRUB from iso-image; just set name
          isoImage.isoName = "chernos-os.iso";

          # Core services
          services.xserver.enable = false;
          programs.sway.enable = true;

          # Kiosk user
          users.users.kiosk = {
            isNormalUser = true;
            password = "kiosk";
            extraGroups = [ "video" "input" ];
          };

          # greetd: login manager that starts sway as kiosk user
          services.greetd.enable = true;
          services.greetd.settings = {
            default_session = {
              command = "${pkgs.sway}/bin/sway";
              user = "kiosk";
            };
          };

          # Packages
          environment.systemPackages = with pkgs; [
            chromium
            swaybg
            vim
          ];

          # Sway config: Chromium kiosk with ChernOS UI
          environment.etc."sway/config".text = ''
            include /etc/sway/config.d/*

            # block usual exit combos
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

    # So CI & you can run: nix build .#iso
    packages.${system}.iso =
      self.nixosConfigurations.chernos-iso.config.system.build.isoImage;
  };
}
