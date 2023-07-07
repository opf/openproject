interface NgSelectShim {
  appendTo?:string;
  dropdownPanel?:{
    _updateXPosition():void;
    _updateYPosition():void;
  }
}

// Force reposition as a workaround for BUG
// https://github.com/ng-select/ng-select/issues/1259
export function repositionDropdownBugfix(component?:unknown) {
  const instance = component as NgSelectShim;
  if (instance?.appendTo && instance?.dropdownPanel) {
    setTimeout(() => {
      // eslint-disable-next-line no-underscore-dangle
      instance.dropdownPanel?._updateXPosition();
      // eslint-disable-next-line no-underscore-dangle
      instance.dropdownPanel?._updateYPosition();
    }, 25);
  }
}
