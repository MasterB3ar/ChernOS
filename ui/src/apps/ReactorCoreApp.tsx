import React, { useEffect, useState } from "react";
import { bus, logLine } from "../core/messageBus";
import { getSimState, toggleOverdrive, injectFault } from "../core/simulation";

export const ReactorCoreApp: React.FC = () => {
  const [temp, setTemp] = useState(0);
  const [pressure, setPressure] = useState(0);
  const [rad, setRad] = useState(0);
  const [crisis, setCrisis] = useState(0);
  const [stage, setStage] = useState(0);
  const [overdrive, setOverdrive] = useState(false);

  useEffect(() => {
    const state = getSimState();
    updateFromState(state);

    const unsub = bus.subscribe((e) => {
      if (e.type === "reactor:update") {
        updateFromState({ reactor: e.payload.reactor } as any);
      }
    });
    return () => unsub();
  }, []);

  function updateFromState(state: any) {
    const r = state.reactor || state;
    setTemp(r.temp);
    setPressure(r.pressure);
    setRad(r.rad);
    setCrisis(r.crisisIndex);
    setStage(r.meltdownStage);
    setOverdrive(r.overdrive);
  }

  function crisisMode(ci: number): string {
    if (ci < 3) return "SAFE";
    if (ci < 6) return "ELEVATED";
    if (ci < 8.5) return "CRITICAL";
    return "REDLINE";
  }

  function onOverdriveClick() {
    toggleOverdrive();
    setOverdrive(!overdrive);
  }

  return (
    <div className="panel reactor">
      <div className="panel-header">
        <span className="label">Redline Crisis Engine</span>
        <span className="pill">
          Mode: {crisisMode(crisis)} · Crisis Index {crisis.toFixed(1)} / 10.0
        </span>
      </div>

      <div className="reactor-grid">
        <div className="core-visual">
          <div className="ring outer" data-stage={stage} />
          <div className="ring mid" data-stage={stage} />
          <div className="ring inner" data-stage={stage} />
          <div className="core-dot" data-stage={stage} />
          <div className="core-readout">
            <div>{Math.round(temp)} °C</div>
            <div>{pressure.toFixed(2)} MPa</div>
            <div>{rad.toFixed(2)} mSv/h</div>
          </div>
        </div>
        <div className="core-controls">
          <div className="label">Controls</div>
          <button className="btn" onClick={onOverdriveClick}>
            Overdrive: {overdrive ? "ON" : "OFF"}
          </button>
          <button className="btn" onClick={() => bus.emit({ type: "audio:play", payload: { id: "siren-low" } })}>
            Test Alarm
          </button>
          <button className="btn" onClick={() => bus.emit({ type: "audio:play", payload: { id: "coolant" } })}>
            Test Coolant Hum
          </button>
          <button className="btn" onClick={() => bus.emit({ type: "audio:play", payload: { id: "test-01" } })}>
            audio test 01
          </button>

          <div className="label mt-3">Simulate fault</div>
          <div className="flex gap-1 flex-wrap">
            <button className="btn-small" onClick={() => injectFault("sensor")}>Sensor misread</button>
            <button className="btn-small" onClick={() => injectFault("pump")}>Pump irregularity</button>
            <button className="btn-small" onClick={() => injectFault("pressure")}>Pressure spike</button>
            <button className="btn-small" onClick={() => injectFault("ghost")}>Ghost radiation</button>
          </div>
          <div className="soft mt-2 text-xs">
            After meltdown stage 5, UI remains in “aftermath mode” (fog, broken gauges – extend here).
          </div>
        </div>
      </div>
    </div>
  );
};
