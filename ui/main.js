(function () {
  function $(id) {
    return document.getElementById(id);
  }

  document.addEventListener("DOMContentLoaded", () => {
    const bootScreen = $("boot-screen");
    const appRoot = $("app-root");
    const enterBtn = $("enter-btn");

    const coreTempEl = $("core-temp");
    const corePressureEl = $("core-pressure");
    const coreLoadEl = $("core-load");
    const coolantFlowEl = $("coolant-flow");
    const containmentEl = $("containment-status");
    const safeguardEl = $("safeguard-charge");
    const statusLabel = $("reactor-status-label");
    const clockEl = $("clock-readout");

    const faultListEl = $("fault-list");
    const btnInjectFault = $("btn-inject-fault");
    const btnClearFaults = $("btn-clear-faults");

    const consoleLogEl = $("console-log");
    const consoleInputEl = $("console-input");

    // 1) Boot → main UI
    if (enterBtn && bootScreen && appRoot) {
      enterBtn.addEventListener("click", () => {
        bootScreen.classList.add("hidden");
        appRoot.classList.remove("hidden");
        logLine(
          "system",
          "Entered control room. Core is under supervised simulation."
        );
      });
    }

    // 2) Clock
    function updateClock() {
      if (!clockEl) return;
      const now = new Date();
      clockEl.textContent = now.toLocaleTimeString("en-GB", {
        hour12: false,
      });
    }

    // 3) Simple reactor simulation
    let temp = 312.4;
    let pressure = 87.3;
    let load = 47.0;
    let flow = 72.1;
    let safeguard = 83.0;

    function clamp(v, lo, hi) {
      return Math.max(lo, Math.min(hi, v));
    }

    function updateReactor() {
      temp = clamp(temp + (Math.random() - 0.5) * 0.9, 300, 340);
      pressure = clamp(pressure + (Math.random() - 0.5) * 0.4, 75, 110);
      load = clamp(load + (Math.random() - 0.5) * 3.0, 20, 99);
      flow = clamp(flow + (Math.random() - 0.5) * 2.0, 40, 100);
      safeguard = clamp(safeguard + (Math.random() - 0.5) * 1.2, 20, 100);

      if (coreTempEl)
        coreTempEl.textContent = temp.toFixed(1) + " K";
      if (corePressureEl)
        corePressureEl.textContent = pressure.toFixed(1) + " bar";
      if (coreLoadEl)
        coreLoadEl.textContent = "Load: " + load.toFixed(0) + "%";
      if (coolantFlowEl)
        coolantFlowEl.textContent = flow.toFixed(1) + " %";
      if (safeguardEl)
        safeguardEl.textContent = safeguard.toFixed(0) + " %";

      // Containment + status
      let status = "Nominal";
      let className = "status-pill status-nominal";
      let containmentText = "Sealed";
      let containmentClass = "metric-value metric-ok";

      if (temp > 333 || pressure > 105) {
        status = "ALERT";
        className = "status-pill status-alert";
        containmentText = "Stressed";
        containmentClass = "metric-value metric-warn";
      } else if (temp > 326 || pressure > 100) {
        status = "Stressed";
        className = "status-pill status-warn";
        containmentText = "Tightened";
        containmentClass = "metric-value metric-warn";
      }

      if (statusLabel) {
        statusLabel.textContent = status;
        statusLabel.className = className;
      }
      if (containmentEl) {
        containmentEl.textContent = containmentText;
        containmentEl.className = containmentClass;
      }
    }

    // 4) Fault simulation
    const activeFaults = [];

    function renderFaults() {
      if (!faultListEl) return;
      faultListEl.innerHTML = "";

      if (activeFaults.length === 0) {
        const li = document.createElement("li");
        li.className = "fault-line fault-empty";
        li.textContent =
          "No active faults. System is running within nominal envelope.";
        faultListEl.appendChild(li);
        return;
      }

      activeFaults.forEach((fault) => {
        const li = document.createElement("li");
        li.className = "fault-line " + fault.severity;
        li.textContent = `[${fault.code}] ${fault.message}`;
        faultListEl.appendChild(li);
      });
    }

    function injectRandomFault() {
      const candidates = [
        {
          code: "PUMP-OSC",
          message: "Coolant pump oscillation detected.",
          severity: "fault-warn",
        },
        {
          code: "SENSOR-GHOST",
          message: "Ghost rad sensor spike – uncorrelated with core output.",
          severity: "fault-warn",
        },
        {
          code: "PRESS-DELTA",
          message: "Rapid pressure delta in containment envelope.",
          severity: "fault-crit",
        },
        {
          code: "FLOW-DROP",
          message: "Transient flow drop on loop B.",
          severity: "fault-warn",
        },
      ];

      const f = candidates[Math.floor(Math.random() * candidates.length)];
      activeFaults.push(f);
      renderFaults();
      logLine("fault", `Injected fault ${f.code}`);
    }

    if (btnInjectFault) {
      btnInjectFault.addEventListener("click", () => {
        injectRandomFault();
      });
    }

    if (btnClearFaults) {
      btnClearFaults.addEventListener("click", () => {
        activeFaults.splice(0, activeFaults.length);
        renderFaults();
        logLine("system", "Fault list cleared.");
      });
    }

    // 5) Console / commands
    function logLine(kind, text) {
      if (!consoleLogEl) return;
      const div = document.createElement("div");
      let cls = "log-line";

      if (kind === "system") cls += " log-system";
      if (kind === "fault") cls += " log-fault";
      if (kind === "audio") cls += " log-audio";
      if (kind === "cmd") cls += " log-cmd";

      div.className = cls;
      div.textContent = `[${kind}] ${text}`;
      consoleLogEl.appendChild(div);
      consoleLogEl.scrollTop = consoleLogEl.scrollHeight;
    }

    function handleCommand(raw) {
      const cmd = raw.trim();
      if (!cmd) return;

      logLine("cmd", cmd);

      const lower = cmd.toLowerCase();

      if (lower.startsWith("audio test")) {
        logLine("audio", "Pretending to play test tone (muted in this build).");
      } else if (lower.startsWith("simulate")) {
        const arg = cmd.split(/\s+/)[1] || "generic";
        logLine("system", `Simulating fault scenario '${arg}'.`);
        injectRandomFault();
      } else if (lower === "help") {
        logLine(
          "system",
          "Commands: 'audio test <id>', 'simulate <code>', 'help', 'clear'."
        );
      } else if (lower === "clear") {
        if (consoleLogEl) consoleLogEl.innerHTML = "";
      } else {
        logLine("system", "Unknown command. Try: help");
      }
    }

    if (consoleInputEl) {
      consoleInputEl.addEventListener("keydown", (ev) => {
        if (ev.key === "Enter") {
          const value = consoleInputEl.value;
          consoleInputEl.value = "";
          handleCommand(value);
        }
      });
    }

    // 6) Start timers
    updateClock();
    updateReactor();
    renderFaults();
    setInterval(updateClock, 1000);
    setInterval(updateReactor, 900);
  });
})();
