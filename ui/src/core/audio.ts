import { bus, logLine } from "./messageBus";

let ctx: AudioContext | null = null;

interface Track {
  osc: OscillatorNode;
  gain: GainNode;
}

const tracks: Record<string, Track | null> = {
  hum: null,
  coolant: null,
  siren: null,
  music: null
};

function ensureCtx() {
  if (!ctx) {
    ctx = new AudioContext();
  }
}

function createTrack(id: string, type: OscillatorType, freq: number, gainVal: number) {
  ensureCtx();
  if (!ctx) return;
  const osc = ctx.createOscillator();
  const gain = ctx.createGain();
  osc.type = type;
  osc.frequency.value = freq;
  gain.gain.value = gainVal;
  osc.connect(gain).connect(ctx.destination);
  osc.start();
  tracks[id] = { osc, gain };
}

function stopTrack(id: string) {
  const t = tracks[id];
  if (!t) return;
  try {
    t.osc.stop();
  } catch {}
  t.gain.disconnect();
  tracks[id] = null;
}

export function initAudioSystem() {
  bus.subscribe((e) => {
    if (e.type === "audio:play") {
      const { id } = e.payload;
      handleAudioPlay(id);
    } else if (e.type === "audio:stop") {
      stopTrack(e.payload.id);
    }
  });

  // Autostart hum
  handleAudioPlay("hum");
  handleAudioPlay("music-ambient");
}

function handleAudioPlay(id: string) {
  switch (id) {
    case "hum":
      if (!tracks.hum) createTrack("hum", "sine", 50, 0.04);
      break;
    case "coolant":
      if (!tracks.coolant) createTrack("coolant", "triangle", 19, 0.03);
      break;
    case "siren-low":
      createTrack(`siren-${Date.now()}`, "sawtooth", 560, 0.08);
      setTimeout(() => stopTrack("siren"), 1200);
      break;
    case "music-ambient":
      if (!tracks.music) createTrack("music", "triangle", 220, 0.01);
      break;
    default:
      // audio test <id>
      logLine(`audio test: playing pseudo-tone id=${id}`);
      createTrack(`test-${id}`, "square", 300 + Math.random() * 400, 0.02);
      setTimeout(() => stopTrack(`test-${id}`), 800);
  }
}
