import { addons } from '@storybook/addons';

const ADDON_ID = 'iframe';

if (window && window.parent) {
  addons.register(ADDON_ID, () => {
    let previousLocation = window.location.toString();
    document.body.addEventListener('click', () => {
      const newLocation = window.location.toString();
      if (previousLocation !== newLocation) {
        window.parent.postMessage(newLocation, '*');
        previousLocation = newLocation;
      }
    });
  });
}
