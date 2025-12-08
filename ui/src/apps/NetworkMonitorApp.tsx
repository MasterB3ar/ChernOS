import React, { useEffect, useState } from "react";
import { bus } from "../core/messageBus";

interface NodeView {
  id: string;
  latency: number;
  loss: number;
  active: boolean;
}

export const NetworkMonitorApp: React.FC = () => {
  const [nodes, setNodes] = useState<NodeView[]>([]);

  useEffect(() => {
    const unsub = bus.subscribe((e) => {
      if (e.type === "net:update") {
        setNodes(e.payload.net.nodes);
      }
    });
    return () => unsub();
  }, []);

  return (
    <div className="panel net">
      <div className="panel-header">
        <span className="label">Network Monitor</span>
        <span className="pill">CORE-1 · FLOW-A · SHIELD-X · DIAG-NET · OPS-TOWER</span>
      </div>
      <div className="net-grid">
        <div className="net-table">
          <div className="net-row head">
            <span>Node</span><span>Latency</span><span>Loss</span><span>Status</span>
          </div>
          {nodes.map((n) => (
            <div key={n.id} className="net-row">
              <span>{n.id}</span>
              <span>{n.latency.toFixed(1)} ms</span>
              <span>{n.loss.toFixed(2)}%</span>
              <span>{n.active ? "ONLINE" : "OFFLINE"}</span>
            </div>
          ))}
        </div>
        <div className="net-topology">
          <div className="graph-label">Topology Map (sim)</div>
          <div className="topology-placeholder" />
          <div className="soft text-xs mt-2">
            Extend with animated packet waves, net status/scan/trace/throttle commands.
          </div>
        </div>
      </div>
    </div>
  );
};
