import type { EarthquakeEvent } from './types';

export class RumbleAudio {
  private ctx: AudioContext | null = null;
  private enabled = true;
  private unlocked = false;

  setMuted(muted: boolean): void {
    this.enabled = !muted;
  }

  unlock = (): void => {
    if (!this.ctx) {
      this.ctx = new AudioContext();
    }

    if (this.ctx.state === 'suspended') {
      void this.ctx.resume();
    }

    this.unlocked = true;
  };

  playFor(event: EarthquakeEvent): void {
    if (!this.enabled || !this.unlocked || event.mag < 3) return;
    const context = this.ctx;
    if (!context) return;

    const now = context.currentTime;
    const duration = 2 + event.mag * 0.5;

    const osc = context.createOscillator();
    osc.type = 'sine';
    osc.frequency.value = 20 + event.mag * 3;

    const noise = context.createBufferSource();
    const noiseBuffer = context.createBuffer(1, context.sampleRate * duration, context.sampleRate);
    const channel = noiseBuffer.getChannelData(0);
    for (let index = 0; index < channel.length; index++) {
      channel[index] = Math.random() * 2 - 1;
    }
    noise.buffer = noiseBuffer;
    noise.loop = false;

    const lowPass = context.createBiquadFilter();
    lowPass.type = 'lowpass';
    lowPass.frequency.value = 90;

    const gain = context.createGain();
    gain.gain.setValueAtTime(0.0001, now);
    gain.gain.linearRampToValueAtTime(Math.min(0.65, event.mag * 0.08), now + 0.3);
    gain.gain.exponentialRampToValueAtTime(0.001, now + duration);

    osc.connect(gain);
    noise.connect(lowPass);
    lowPass.connect(gain);
    gain.connect(context.destination);

    osc.start(now);
    noise.start(now);
    osc.stop(now + duration);
    noise.stop(now + duration);
  }
}
