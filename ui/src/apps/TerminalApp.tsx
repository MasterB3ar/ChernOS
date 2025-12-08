import React, { useState, useEffect } from "react";
import { bus, logLine } from "../core/messageBus";
import {
  getSimState,
  injectFault,
  netStatusSummary,
  netScan,
  netTrace,
  netThrottle
} from "../core/simulation";

interface Line {
  id: string;
  text: string;
}

export const TerminalApp: React.FC = () => {
  const [input, setInput] = useState("");
  const [lines, setLines] = useState<Line[]>([]);
  const [history, setHistory] = useState<string[]>([]);
  const [historyIndex, setHistoryIndex] = useState<number>(-1);

  useEffect(() => {
    printLine("ChernOS Operator Terminal Mk II");
    printLine('Type "help" for commands.');
  }, []);

  function printLine(text: string) {
    setLines((prev) => [...prev, { id: `${Date.now()}-${Math.random()}`, text }].slice(-300));
  }

  function handleCommand(raw: string) {
    const cmd = raw.trim();
    if (!cmd) return;

    printLine(`> ${cmd}`);
    logLine(`term: ${cmd}`);
    setHistory((prev) => [cmd, ...prev]);
    setHistoryIndex(-1);

    const lower = cmd.toLowerCase();

    if (lower === "help") {
      printLine(
        "commands: help, status, containment status, simulate <sensor|pump|pressure|ghost>, audio test <id>, theme <green|amber|redline|blackchamber|night>, net status, net scan, net trace <node>, net throttle <0|1|2>"
      );
      return;
    }

    if (lower === "status") {
      const s = getSimState();
      const r = s.reactor;
      printLine(
        `reactor: T=${Math.round(r.temp)}C P=${r.pressure.toFixed(
          2
        )}MPa rad=${r.rad.toFixed(2)}mSv/h sg=${r.safeguards} stage=${r.meltdownStage} crisis=${r.crisisIndex.toFixed(
          1
        )}/10`
      );
      return;
    }

    if (lower === "containment status") {
      const s = getSimState();
      const c = s.containment;
      printLine(
        `containment: alpha=${c.alpha} betaLatched=${c.betaLatched} gamma=${c.gamma} secondary=${c.secondaryIntegrity.toFixed(
          1
        )}%`
      );
      return;
    }

    if (lower.startsWith("simulate ")) {
      const kind = lower.split(/\s+/)[1];
      if (!["sensor", "pump", "pressure", "ghost"].includes(kind)) {
        printLine("simulate: expected one of sensor|pump|pressure|ghost");
        return;
      }
      injectFault(kind as any);
      printLine(`simulate: fault '${kind}' injected (sim).`);
      return;
    }

    if (lower.startsWith("audio test ")) {
      const id = cmd.slice("audio test ".length).trim() || "test";
      bus.emit({ type: "audio:play", payload: { id } });
      printLine(`audio test: playing id=${id} (sim tone).`);
      return;
    }

    if (lower.startsWith("theme ")) {
      const t = lower.split(/\s+/)[1];
      if (!["green", "amber", "redline", "blackchamber", "night"].includes(t)) {
        printLine("theme: use green|amber|redline|blackchamber|night");
        return;
      }
      bus.emit({ type: "theme:set", payload: { theme: t } });
      printLine(`theme set: ${t}`);
      return;
    }

    if (lower === "net status") {
      printLine(netStatusSummary());
      return;
    }

    if (lower === "net scan") {
      const nodes = netScan();
      printLine(`net scan: ${nodes.join(", ") || "no nodes online"}`);
      return;
    }

    if (lower.startsWith("net trace ")) {
      const node = cmd.slice("net trace ".length).trim();
      if (!node) {
        printLine("net trace: missing node id.");
        return;
      }
      const msg = netTrace(node);
      printLine(msg);
      return;
    }

    if (lower.startsWith("net throttle ")) {
      const rawLevel = lower.split(/\s+/)[2];
      const n = parseInt(rawLevel, 10);
      if (Number.isNaN(n)) {
        printLine("net throttle: expected integer 0–2.");
        return;
      }
      const msg = netThrottle(n);
      printLine(msg);
      return;
    }

    printLine('Unknown command – try "help".');
  }

  function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    const cmd = input;
    setInput("");
    handleCommand(cmd);
  }

  function onKeyDown(e: React.KeyboardEvent<HTMLInputElement>) {
    if (e.key === "ArrowUp") {
      e.preventDefault();
      if (history.length === 0) return;
      const nextIndex = Math.min(history.length - 1, historyIndex + 1);
      setHistoryIndex(nextIndex);
      setInput(history[nextIndex]);
    } else if (e.key === "ArrowDown") {
      e.preventDefault();
      if (history.length === 0) return;
      if (historyIndex <= 0) {
        setHistoryIndex(-1);
        setInput("");
      } else {
        const nextIndex = historyIndex - 1;
        setHistoryIndex(nextIndex);
        setInput(history[nextIndex]);
      }
    }
  }

  return (
    <div className="panel terminal">
      <div className="panel-header">
        <span className="label">Operator Terminal Mk II</span>
        <span className="pill">Auto-complete & history (basic)</span>
      </div>
      <div className="terminal-body">
        <div className="terminal-output">
          {lines.map((l) => (
            <div key={l.id} className="terminal-line">
              {l.text}
            </div>
          ))}
        </div>
        <form className="terminal-input-row" onSubmit={onSubmit}>
          <span className="prompt">OP&gt;</span>
          <input
            className="terminal-input"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            onKeyDown={onKeyDown}
            spellCheck={false}
            autoComplete="off"
          />
        </form>
      </div>
    </div>
  );
};
