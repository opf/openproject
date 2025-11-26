import { type WorkPackage, type OpColorMode } from "../openProjectTypes";
import { fetchTypes, fetchStatuses } from "./openProjectApi";
import { useEffect, useState } from "react";

const FALLBACK_TYPE_COLOR = "#3f3f3f";
const FALLBACK_STATUS_COLOR = "#D2DAE4";

const statusColors:Record<string, string> = {};
const typeColors:Record<string, string> = {};
let colorsPromise: Promise<void> | null = null;

// Load colors only once (called when OpenProjectWorkPackageBlock is initialized).
// And ensure that the component is re-rendered after colors are loaded.
export function useColors() {
  const [isLoaded, setIsLoaded] = useState(() =>
    Object.keys(typeColors).length > 0 && Object.keys(statusColors).length > 0
  );

  useEffect(() => {
    if (isLoaded) return;

    let active = true;
    cacheColors().then(() => {
      if (active) {
        setIsLoaded(true);
      }
    });

    return () => {
      active = false;
    };
  }, [isLoaded]);

  return isLoaded;
}

export function cacheColors(): Promise<void> {
  if (colorsPromise) {
    return colorsPromise;
  }

  colorsPromise = Promise.all([
    (async () => {
      if (Object.keys(typeColors).length > 0) return;
      const data = await fetchTypes();
      data._embedded?.elements?.forEach(element => {
        if (element.color) {
          typeColors[element.id] = element.color;
        }
      });
    })(),
    (async () => {
      if (Object.keys(statusColors).length > 0) return;
      const data = await fetchStatuses();
      data._embedded?.elements?.forEach(element => {
        if (element.color) {
          statusColors[element.id] = element.color;
        }
      });
    })(),
  ]).then(() => {});

  return colorsPromise;
}

export function typeColor(workPackage: WorkPackage) {
  if (!workPackage._links || !workPackage._links.type) {
    return FALLBACK_TYPE_COLOR;
  }
  const typeId = idFromHref(workPackage._links.type.href) ?? "";
  return typeColors[typeId] || FALLBACK_TYPE_COLOR;
}

export function statusColor(workPackage: WorkPackage) {
  if (!workPackage._links || !workPackage._links.status) {
    return FALLBACK_STATUS_COLOR;
  }
  const statusId = idFromHref(workPackage._links.status.href) ?? "";
  return statusColors[statusId] || FALLBACK_STATUS_COLOR;
}

export function defaultColorStyles(hexColor: string) {
  const hsl = hexToHSL(hexColor);
  return `
    --color-r: ${parseHexColorValue(hexColor, "r")};
    --color-g: ${parseHexColorValue(hexColor, "g")};
    --color-b: ${parseHexColorValue(hexColor, "b")};
    --color-h: ${hsl.h};
    --color-s: ${hsl.s};
    --color-l: ${hsl.l};
    --perceived-lightness: calc( ((var(--color-r) * 0.2126) + (var(--color-g) * 0.7152) + (var(--color-b) * 0.0722)) / 255 );
    --lightness-switch: max(0, min(calc((1/(var(--lightness-threshold) - var(--perceived-lightness)))), 1)); 
    --lighten-by: calc(((var(--lightness-threshold) - var(--perceived-lightness)) * 100) * var(--lightness-switch));
    `
}

export function defaultVariables() {
  if (getTheme() === "dark") {
    return `
      --lightness-threshold: 0.6;
      --background-alpha: 0.10; // this is darker than the default of OpenProject, but BlockNotes dark mode backgrounds are lighter
  `;
  }

  return `
    --lightness-threshold: 0.453; 
  `
}

export function statusBorderColor() {
  if (getTheme() === "dark") {
    return wantsHighContrast()
      ? `hsl(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) + 10 + var(--lighten-by)) * 1%))`
      : `hsl(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) + var(--lighten-by)) * 1%))`;
  }

  // light theme
  return wantsHighContrast()
    ? `hsla(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) - 75) * 1%), 1)`
    : `hsl(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) - 15) * 1%))`;
}

export function statusBackgroundColor() {
  if (getTheme() === "dark") return `rgba(var(--color-r), var(--color-g), var(--color-b), var(--background-alpha))`;

  // light theme
  return `rgb(var(--color-r), var(--color-g), var(--color-b))`;
}

export function statusTextColor() {
  if (getTheme() === "dark") return `hsl(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) + var(--lighten-by)) * 1%))`;

  //light theme
  return `hsl(0deg, 0%, calc(var(--lightness-switch) * 100%))`
}

export function typeTextColor() {
  if (getTheme() === "dark") {
    return wantsHighContrast()
      ? `hsla(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) + 10 + var(--lighten-by)) * 1%), 1)`
      : `hsla(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) + var(--lighten-by)) * 1%), 1)`;
  }

  // light theme
  return  wantsHighContrast()
    ? `hsla(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) - (var(--color-l) * 0.5)) * 1%), 1)`
    : `hsla(var(--color-h), calc(var(--color-s) * 1%), calc((var(--color-l) - (var(--color-l) * 0.22)) * 1%), 1)`;
}

function hexToHSL(hexColor: string): { h: number; s: number; l: number } {
  const color = cleanColorString(hexColor);

  const r = parseHexColorValue(color, "r") / 255;
  const g = parseHexColorValue(color, "g") / 255;
  const b = parseHexColorValue(color, "b") / 255;

  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  let h = 0;
  let s = 0;
  const l = (max + min) / 2;

  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);

    switch (max) {
      case r:
        h = (g - b) / d + (g < b ? 6 : 0);
        break;
      case g:
        h = (b - r) / d + 2;
        break;
      case b:
        h = (r - g) / d + 4;
        break;
    }
    h /= 6;
  }

  return {h: Math.round(h * 360), s: Math.round(s * 100), l: Math.round(l * 100)};
}

function parseHexColorValue(colorString: string, channel: "r" | "g" | "b"): number {
  const color = cleanColorString(colorString);
  let colorSubString;
  switch (channel) {
    case "r": colorSubString = color.substring(0, 2); break;
    case "g": colorSubString = color.substring(2, 4); break;
    case "b": colorSubString = color.substring(4, 6); break;
  }
  return parseInt(colorSubString, 16);
}

function cleanColorString(colorString: string) {
  return colorString
    .replace("#", "")
    .padEnd(6, "0");
}

function idFromHref(href: string) {
  return href.split("/").pop();
}

let theme: OpColorMode;
function getTheme(): OpColorMode {
  return theme ?? (theme = detectTheme());
}

function detectTheme(): OpColorMode {
  const detected = document.querySelector('.bn-container')?.getAttribute('data-color-scheme');

  if (detected === "light" || detected === "dark") {
    return detected;
  }

  return "light";
}

let highContrast: boolean;
function wantsHighContrast(): boolean {
  return highContrast ?? (highContrast = detectHighContrast());
}

function detectHighContrast(): boolean {
  const osContrast = window.matchMedia('(prefers-contrast: more)');
  const opContrast = document.querySelector('body')?.getAttribute('data-auto-theme-switcher-increase-contrast-value');
  const opForceLightContrast = document.querySelector('body')?.getAttribute('data-auto-theme-switcher-force-light-contrast-value');
  const opForceDarkContrast = document.querySelector('body')?.getAttribute('data-auto-theme-switcher-force-dark-contrast-value');

  return ((osContrast.matches && !(opContrast === "false")) || opContrast === "true" || (getTheme() == "light" && opForceLightContrast === "true") || (getTheme() == "dark" && opForceDarkContrast === "true"));
}
