import React, { useEffect, useState } from "react";
import { bus } from "../core/messageBus";

export const ContainmentApp: React.FC = () => {
  const [sec, setSec] = useState(100);
  const [alpha, setAlpha] = useState(false);
  const [beta, setBeta] = useState(false);
  const [gamma, setGamma] = useState(false);

  useEffect(() => {
    const unsub = bus.subscribe((e) => {
      if (e.type === "containment:update") {
        const c = e.payload.containment;
        setSec(c.secondaryIntegrity);
        setAlpha(c.alpha);
        setBeta(c.betaLatched);
        setGamma(c.gamma);
      }
    });
    return () => unsub();
  }, []);

  function statusColor() {
    if (sec > 60) return "ok";
    if (sec > 30) return "warn";
    return "crit";
  }

  return (
    <div className="panel containment">
      <div className="panel-header">
        <span className="label">Containment Manager</span>
        <span className={`pill ${statusColor()}`}>Secondary Integrity {sec.toFixed(1)}%</span>
      </div>
      <div className="containment-grid">
        <div className="chamber-visual" data-level={statusColor()}>
          <div className="fracture-layer" data-int={sec} />
        </div>
        <div className="containment-controls">
          <div className="soft text-xs mb-2">
            CFA / CFB / CFG map to thermal buffer, pressure latch, gamma field.  
            Micro-fractures grow as integrity drops.
          </div>
          <div className="pill-row">
            <span className={`pill ${alpha ? "on" : "off"}`}>CFA (Thermal)</span>
            <span className={`pill ${beta ? "on" : "off"}`}>CFB (Pressure)</span>
            <span className={`pill ${gamma ? "on" : "off"}`}>CFG (Gamma)</span>
          </div>
          <div className="soft text-xs mt-3">
            Extend: add manual coolant routing UI, seal level &lt;x&gt;, dampers, etc.
          </div>
        </div>
      </div>
    </div>
  );
};
