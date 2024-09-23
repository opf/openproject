export const onboardingTourStorageKey = 'openProject-onboardingTour';
export type OnboardingTourNames = 'homescreen'|'workPackages'|'gantt'|'final'|'boards'|'teamPlanner';

function matchingFilter(list:NodeListOf<HTMLElement>, filterFunction:(match:HTMLElement) => boolean):HTMLElement|null {
  for (let i = 0; i < list.length; i++) {
    if (filterFunction(list[i])) {
      return list[i];
    }
  }

  return null;
}

export function waitForElement(
  selector:string,
  containerSelector:string,
  execFunction:(match:HTMLElement) => void,
  filterFunction:(match:HTMLElement) => boolean = () => true,
):void {
  const container = document.querySelector(containerSelector) as HTMLElement;
  // If the element is ready immediately
  const initial = matchingFilter(container.querySelectorAll<HTMLElement>(selector), filterFunction);
  if (initial) {
    execFunction(initial);
    return;
  }

  // Wait for the element to be ready
  const observer = new MutationObserver((mutations, observerInstance) => {
    const matches = matchingFilter(container.querySelectorAll<HTMLElement>(selector), filterFunction);
    if (matches) {
      execFunction(matches);
      observerInstance.disconnect();
    }
  });

  observer.observe(container, {
    childList: true,
    subtree: true,
  });
}
