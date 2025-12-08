import React from "react";

export const LogViewerApp: React.FC<{ lines: string[] }> = ({ lines }) => {
  return (
    <div className="panel logs">
      <div className="panel-header">
        <span className="label">Event Log Analyzer</span>
        <span className="pill">Simulation / Fault / Net / Audio</span>
      </div>
      <div className="log-body">
        {lines.map((l, i) => (
          <div key={i} className="log-line">
            {l}
          </div>
        ))}
      </div>
    </div>
  );
};
