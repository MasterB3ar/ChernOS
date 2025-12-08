import React from "react";

export const DiagnosticsApp: React.FC = () => {
  return (
    <div className="panel diag">
      <div className="panel-header">
        <span className="label">Diagnostics Suite</span>
        <span className="pill">Live Telemetry + Net Graphs</span>
      </div>
      <div className="graphs-grid">
        <div className="graph-card">
          <div className="graph-label">Core Temp</div>
          <div className="graph-placeholder" />
        </div>
        <div className="graph-card">
          <div className="graph-label">Pressure</div>
          <div className="graph-placeholder" />
        </div>
        <div className="graph-card">
          <div className="graph-label">Radiation</div>
          <div className="graph-placeholder" />
        </div>
        <div className="graph-card">
          <div className="graph-label">Network Load</div>
          <div className="graph-placeholder" />
        </div>
      </div>
    </div>
  );
};
