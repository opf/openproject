interface NgSelectShim {
  appendTo?:string;
  dropdownPanel?:(() => { adjustPosition():void })|{ adjustPosition():void };
}

// Force reposition as a workaround for BUG
// https://github.com/ng-select/ng-select/issues/1259
export function repositionDropdownBugfix(component?:unknown) {
  const instance = component as NgSelectShim;
  if (instance?.appendTo && instance?.dropdownPanel) {
    setTimeout(() => {
      // dropdownPanel is a Signal in ng-select v21+, call it to get the panel instance
      const panelOrSignal = instance.dropdownPanel;
      const panel = typeof panelOrSignal === 'function' ? panelOrSignal() : panelOrSignal;
      panel?.adjustPosition();
    }, 25);
  }
}
