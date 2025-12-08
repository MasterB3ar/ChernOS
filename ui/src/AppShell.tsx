import React, { useEffect, useState } from "react";
import { applyTheme } from "./core/themes";
import { initSimulation, getSimState } from "./core/simulation";
import { initAudioSystem } from "./core/audio";
import { initHotkeys } from "./core/hotkeys";
import { bus, logLine } from "./core/messageBus";
import { loadState, saveState } from "./core/persistence";

import { ReactorCoreApp } from "./apps/ReactorCoreApp";
import { DiagnosticsApp } from "./apps/DiagnosticsApp";
import { ContainmentApp } from "./apps/ContainmentApp";
import { NetworkMonitorApp } from "./apps/NetworkMonitorApp";
import { LogViewerApp } from "./apps/LogViewerApp";

type AppId = "reactor" | "diag" | "containment" | "net" | "log";

interface WindowDef {
  id: string;
  appId: AppId;
  title: string;
  x: number;
  y: number;
  z: number;
}

let zCounter = 10;

export const AppShell: React.FC = () => {
  const [windows, setWindows] = useState<WindowDef[]>([]);
  const [logs, setLogs] = useState<string[]>([]);
  const [theme, setTheme] = useState(loadState().theme);

  useEffect(() => {
    applyTheme(theme);
    const s = loadState();
    saveState({ ...s, theme });

    initSimulation();
    initAudioSystem();
    initHotkeys();

    const unsub = bus.subscribe((e) => {
      if (e.type === "log:append") {
        setLogs((prev) => [e.payload.line, ...prev].slice(0, 400));
      } else if (e.type === "theme:set") {
        setTheme(e.payload.theme as any);
      } else if (e.type === "reactor:update") {
        // if crisis index high, auto switch theme redline / blackchamber
        const ci = e.payload.reactor.crisisIndex;
        if (ci >= 9.0 && theme !== "blackchamber") {
          setTheme("blackchamber");
        } else if (ci >= 7.0 && theme !== "redline") {
          setTheme("redline");
        }
      }
    });

    logLine("ChernOS 2.0 environment initialized.");
    openWindow("reactor");
    openWindow("diag");
    openWindow("log");

    return () => unsub();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    applyTheme(theme);
    const s = loadState();
    saveState({ ...s, theme });
  }, [theme]);

  function openWindow(appId: AppId) {
    setWindows((prev) => [
      ...prev,
      {
        id: `${appId}-${Date.now()}`,
        appId,
        title: appIdToTitle(appId),
        x: 80 + prev.length * 40,
        y: 60 + prev.length * 30,
        z: zCounter++
      }
    ]);
  }

  function bringToFront(id: string) {
    setWindows((prev) =>
      prev.map((w) => (w.id === id ? { ...w, z: zCounter++ } : w))
    );
  }

  function closeWindow(id: string) {
    setWindows((prev) => prev.filter((w) => w.id !== id));
  }

  function appIdToTitle(appId: AppId) {
    switch (appId) {
      case "reactor":
        return "Reactor Core";
      case "diag":
        return "Diagnostics";
      case "containment":
        return "Containment Manager";
      case "net":
        return "Network Monitor";
      case "log":
        return "Event Log Analyzer";
    }
  }

  function renderApp(appId: AppId) {
    switch (appId) {
      case "reactor":
        return <ReactorCoreApp />;
      case "diag":
        return <DiagnosticsApp />;
      case "containment":
        return <ContainmentApp />;
      case "net":
        return <NetworkMonitorApp />;
      case "log":
        return <LogViewerApp lines={logs} />;
    }
  }

  return (
    <div className="chernos-root">
      {/* taskbar */}
      <div className="taskbar">
        <div className="taskbar-left">
          <span className="logo">ChernOS 2.0</span>
          <button onClick={() => openWindow("reactor")}>Reactor</button>
          <button onClick={() => openWindow("diag")}>Diagnostics</button>
          <button onClick={() => openWindow("containment")}>Containment</button>
          <button onClick={() => openWindow("net")}>Network</button>
          <button onClick={() => openWindow("log")}>Logs</button>
        </div>
        <div className="taskbar-right">
          <button onClick={() => setTheme("green")}>G</button>
          <button onClick={() => setTheme("amber")}>A</button>
          <button onClick={() => setTheme("redline")}>R</button>
          <button onClick={() => setTheme("night")}>N</button>
          <button onClick={() => setTheme("blackchamber")}>BC</button>
        </div>
      </div>

      {/* wallpapers / background */}
      <div className="background-glow" />

      {/* windows */}
      {windows.map((w) => (
        <div
          key={w.id}
          className="chernos-window"
          style={{ left: w.x, top: w.y, zIndex: w.z }}
          onMouseDown={() => bringToFront(w.id)}
        >
          <div className="window-titlebar">
            <span>{w.title}</span>
            <div className="window-actions">
              <button onClick={() => closeWindow(w.id)}>✕</button>
            </div>
          </div>
          <div className="window-body">{renderApp(w.appId)}</div>
        </div>
      ))}
    </div>
  );
};
