import { onTestFinished, vi } from 'vitest';

class StandInViewport extends EventTarget {
  occluded = 0;

  offsetTop = 0;

  scale = 1;

  get width():number { return window.innerWidth / this.scale; }

  get height():number { return (window.innerHeight - this.occluded) / this.scale; }

  get pageTop():number { return window.scrollY + this.offsetTop; }

  get pageLeft():number { return window.scrollX; }
}

export interface StandInVisualViewport {
  raiseKeyboard:(height:number) => void;
  lowerKeyboard:() => void;
  scrollTo:(offsetTop:number) => void;
  pinchTo:(scale:number) => void;
  readClientRectsOffTheVisualViewport:() => void;
}

export function standInVisualViewport():StandInVisualViewport {
  const viewport = new StandInViewport();
  Object.defineProperty(window, 'visualViewport', { configurable: true, get: () => viewport });
  onTestFinished(() => { delete (window as { visualViewport?:unknown }).visualViewport; });

  const resized = () => viewport.dispatchEvent(new Event('resize'));

  return {
    raiseKeyboard: (height) => { viewport.occluded = height; resized(); },
    lowerKeyboard: () => { viewport.occluded = 0; resized(); },
    scrollTo: (offsetTop) => { viewport.offsetTop = offsetTop; viewport.dispatchEvent(new Event('scroll')); },
    pinchTo: (scale) => { viewport.scale = scale; resized(); },
    readClientRectsOffTheVisualViewport: () => {
      const root = document.documentElement;
      const readRect = root.getBoundingClientRect.bind(root);
      const spy = vi.spyOn(root, 'getBoundingClientRect').mockImplementation(() => {
        const rect = readRect();
        return new DOMRect(-viewport.pageLeft, -viewport.pageTop, rect.width, rect.height);
      });
      onTestFinished(() => spy.mockRestore());
    },
  };
}
