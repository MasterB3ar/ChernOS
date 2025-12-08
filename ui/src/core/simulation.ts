import { bus, logLine } from "./messageBus";

export type FaultKind = "sensor" | "pump" | "pressure" | "ghost";

export interface ReactorState {
  temp: number;
  pressure: number;
  rad: number;
  safeguards: number;
  meltdownStage: 0 | 1 | 2 | 3 | 4 | 5;
  crisisIndex: number; // 0.0 – 10.0
  overdrive: boolean;
}

export interface ContainmentState {
  alpha: boolean;
  betaLatched: boolean;
  gamma: boolean;
  secondaryIntegrity: number; // 0–100
}

export interface NetNode {
  id: string;
  latency: number;
  loss: number;
  active: boolean;
}

export interface NetState {
  mode: "online" | "degraded" | "offline";
  nodes: NetNode[];
}

export interface CoreSimState {
  reactor: ReactorState;
  containment: ContainmentState;
  net: NetState;
}

const sim: CoreSimState = {
  reactor: {
    temp: 320,
    pressure: 1.3,
    rad: 0.14,
    safeguards: 3,
    meltdownStage: 0,
    crisisIndex: 0.2,
    overdrive: false
  },
  containment: {
    alpha: false,
    betaLatched: false,
    gamma: false,
    secondaryIntegrity: 100
  },
  net: {
    mode: "online",
    nodes: [
      { id: "CORE-1", latency: 12, loss: 0.1, active: true },
      { id: "FLOW-A", latency: 15, loss: 0.2, active: true },
      { id: "SHIELD-X", latency: 18, loss: 0.3, active: true },
      { id: "DIAG-NET", latency: 10, loss: 0.1, active: true },
      { id: "OPS-TOWER", latency: 20, loss: 0.4, active: true }
    ]
  }
};

export function getSimState(): CoreSimState {
  return JSON.parse(JSON.stringify(sim));
}

export function toggleOverdrive() {
  if (sim.reactor.meltdownStage > 0) {
    logLine("Overdrive locked: meltdown chain already in progress (sim).");
    return;
  }
  sim.reactor.overdrive = !sim.reactor.overdrive;
  logLine(`Overdrive ${sim.reactor.overdrive ? "enabled" : "disabled"} (sim exaggeration).`);
}

export function injectFault(kind: FaultKind) {
  switch (kind) {
    case "sensor":
      sim.reactor.temp += 120 + Math.random() * 80;
      logLine("FAULT (sensor misread): temp spike visualized (sim).");
      break;
    case "pump":
      sim.reactor.pressure += 1.6;
      logLine("FAULT (coolant pump irregularity): pressure surge (sim).");
      break;
    case "pressure":
      sim.reactor.pressure += 2.5;
      sim.reactor.rad += 0.3;
      logLine("FAULT (pressure spike): coupling strain + leakage (sim).");
      break;
    case "ghost":
      sim.reactor.rad += 1.2;
      logLine("FAULT (ghost radiation event): anomalous flux (sim).");
      break;
  }
  bus.emit({ type: "reactor:fault", payload: { kind } });
}

function updateNet(dt: number) {
  const jitter = (Math.random() - 0.5) * 4;
  for (const node of sim.net.nodes) {
    if (!node.active) continue;
    node.latency = Math.max(5, node.latency + jitter);
    node.loss = Math.max(0, node.loss + (Math.random() - 0.5) * 0.3);
  }
  bus.emit({ type: "net:update", payload: { net: sim.net } });
}

function updateContainment(dt: number) {
  // Safeguard recharge
  if (sim.reactor.safeguards < 3) {
    if (Math.random() < 0.001 * dt) {
      sim.reactor.safeguards += 1;
      logLine("Safeguard bank recharged (sim).");
    }
  }

  // Secondary integrity drops if meltdown > 0
  if (sim.reactor.meltdownStage > 0) {
    sim.containment.secondaryIntegrity = Math.max(
      0,
      sim.containment.secondaryIntegrity - 0.02 * dt * sim.reactor.meltdownStage
    );
  } else {
    // Slow heal
    sim.containment.secondaryIntegrity = Math.min(
      100,
      sim.containment.secondaryIntegrity + 0.005 * dt
    );
  }

  bus.emit({ type: "containment:update", payload: { containment: sim.containment } });
}

function updateReactor(dt: number) {
  const r = sim.reactor;
  let dT = (Math.random() - 0.5) * 3;
  let dP = (Math.random() - 0.5) * 0.03;
  let dR = (Math.random() - 0.5) * 0.02;

  const drive = r.overdrive ? 1.2 : 0.9;

  dT += (drive - 0.9) * 8;
  dP += (r.temp - 300) / 2600;
  dR += Math.max(0, (r.temp - 450)) / 7000;

  const c = sim.containment;
  if (c.alpha) dT *= 0.8;
  if (c.betaLatched) dP *= 0.5;
  if (c.gamma) dR *= 0.7;

  // meltdown chain
  if (r.meltdownStage === 0) {
    if (r.temp > 1250 && r.safeguards > 0) {
      r.safeguards -= 1;
      r.temp -= 280;
      r.pressure -= 0.9;
      r.rad -= 0.2;
      logLine("AUTO-SG: staged insertion + coolant surge (sim).");
    }
    if (r.temp > 1350 && r.pressure > 5.0 && r.safeguards === 0) {
      r.meltdownStage = 1;
      logLine("MELTDOWN STAGE 1: overheat initiated (sim).");
    }
  } else if (r.meltdownStage === 1) {
    dT += 12;
    dP += 0.08;
    dR += 0.1;
    if (r.temp > 1450) {
      r.meltdownStage = 2;
      logLine("MELTDOWN STAGE 2: pressure runaway (sim).");
    }
  } else if (r.meltdownStage === 2) {
    dT += 18;
    dP += 0.03;
    dR += 0.2;
    if (r.rad > 1.7) {
      r.meltdownStage = 3;
      logLine("MELTDOWN STAGE 3: containment breach (visual) (sim).");
    }
  } else if (r.meltdownStage === 3) {
    dT += 22;
    dP -= 0.04;
    dR += 0.35;
    if (sim.containment.secondaryIntegrity < 50) {
      r.meltdownStage = 4;
      logLine("MELTDOWN STAGE 4: core destabilization (sim).");
    }
  } else if (r.meltdownStage === 4) {
    dT += 10;
    dP -= 0.1;
    dR += 0.2;
    if (sim.containment.secondaryIntegrity < 20) {
      r.meltdownStage = 5;
      logLine("MELTDOWN STAGE 5: reactor collapse aftermath mode (sim).");
    }
  } else if (r.meltdownStage === 5) {
    // Aftermath: cool but broken
    dT -= 14;
    dP = Math.min(r.pressure, r.pressure - 0.15);
    dR -= 0.25;
  }

  r.temp = Math.max(260, r.temp + dT * dt);
  r.pressure = Math.max(0.9, r.pressure + dP * dt);
  r.rad = Math.max(0.05, r.rad + dR * dt);

  // crisis index 0–10
  let ci = 0;
  ci += Math.max(0, (r.temp - 350) / 100);    // up to ~10
  ci += Math.max(0, (r.pressure - 2.0) * 1.5);
  ci += r.rad * 0.8;
  ci += r.meltdownStage * 0.7;
  ci += (100 - sim.containment.secondaryIntegrity) / 40;

  r.crisisIndex = Math.min(10, parseFloat(ci.toFixed(1)));

  bus.emit({ type: "reactor:update", payload: { reactor: r } });
}

export function initSimulation() {
  let last = performance.now();

  function tick(now: number) {
    const dtMs = now - last;
    last = now;
    const dt = dtMs / 1000;

    updateReactor(dt);
    updateContainment(dt);
    updateNet(dt);

    requestAnimationFrame(tick);
  }

  requestAnimationFrame(tick);

  logLine("Core simulation engine (ChernOS 2.0) started @ ~60Hz.");
}
