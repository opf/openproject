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

export function statusBorderColor(hexColor: string) {
  const hsl = hexToHSL(hexColor);

  if(detectTheme() === "dark") return `hsl(${hsl.h}, ${hsl.s}%, ${(hsl.l + lightenBy(hexColor))}%)`;

  // light theme
  return `hsl(${hsl.h}, ${hsl.s}%, ${(hsl.l - 15)}%)`;
}

export function statusTextColor(hexColor: string) {
  const hsl = hexToHSL(hexColor);

  if (detectTheme() === "dark") return `hsl(${hsl.h}, ${hsl.s}%, ${(hsl.l + lightenBy(hexColor))}%)`;

  // light theme
  return `hsl(0deg, 0%, ${lightnessSwitch(hexColor)*100}%)`;
}

export function statusBackgroundColor(hexColor: string) {
  if (detectTheme() === "dark") return `rgba(${parseHexColorValue(hexColor, "r")}, ${parseHexColorValue(hexColor, "g")}, ${parseHexColorValue(hexColor, "b")}, ${backgroundAlpha()})`;

  // light theme
  return hexColor;
}

function lightnessSwitch(hexColor: string) {
  return Math.max(0, Math.min(1/lightnessThreshold() - perceivedLightness(hexColor), 1));
}

function perceivedLightness(color: string) {
  const r = parseHexColorValue(color, "r");
  const g = parseHexColorValue(color, "g");
  const b = parseHexColorValue(color, "b");

  return ((r * 0.2126) + (g * 0.7152) + (b * 0.0722)) / 255;
}

function lightnessThreshold() {
  if(getTheme() === "dark") return 0.6;

  // light theme
  return 0.453;
}

function lightenBy(hexColor: string) {
  // so far only used for dark theme
  return ((lightnessThreshold() - perceivedLightness(hexColor)) * 100) * lightnessSwitch(hexColor);
}

function backgroundAlpha() {
  // so far only used for dark theme
  return 0.18 - 0.07; // darken a bit because BlockNotes dark-mode background is lighter than OpenProjects
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