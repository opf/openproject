import { expect } from 'vitest';

export interface Recording<T> {
  frames:T[];
  stop:() => void;
}

export function recordFrames<T>(sample:() => T | null):Recording<T> {
  const frames:T[] = [];
  let recording = true;

  const tick = () => {
    if (!recording) return;
    const frame = sample();
    if (frame !== null) frames.push(frame);
    requestAnimationFrame(tick);
  };
  requestAnimationFrame(tick);

  return { frames, stop: () => { recording = false; } };
}

export async function untilStill(element:Element):Promise<void> {
  await expect.poll(() => element.getAnimations().length).toBe(0);
}

export const ascending = (values:number[]):number[] => [...values].sort((a, b) => a - b);
export const descending = (values:number[]):number[] => [...values].sort((a, b) => b - a);
