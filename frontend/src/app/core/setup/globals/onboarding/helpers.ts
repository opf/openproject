export const demoProjectName = 'Demo project';
export const scrumDemoProjectName = 'Scrum project';
export const onboardingTourStorageKey = 'openProject-onboardingTour';
export type OnboardingTourNames = 'backlogs'|'taskboard'|'homescreen'|'main';

export function waitForElement(element:string, container:string, execFunction:Function) {
  // Wait for the element to be ready
  var observer = new MutationObserver(function (mutations, observerInstance) {
    if (jQuery(element).length) {
      observerInstance.disconnect(); // stop observing
      execFunction();
      return;
    }
  });
  observer.observe(jQuery(container)[0], {
    childList: true,
    subtree: true
  });
}

export function demoProjectsLinks() {
  const demoProjects = [];
  const demoProjectsLink = jQuery(".widget-box.welcome a:contains(" + demoProjectName + ")");
  const scrumDemoProjectsLink = jQuery(".widget-box.welcome a:contains(" + scrumDemoProjectName + ")");

  if (demoProjectsLink.length) {
    demoProjects.push(demoProjectsLink);
  }
  if (scrumDemoProjectsLink.length) {
    demoProjects.push(scrumDemoProjectsLink);
  }

  return demoProjects;
}

export function preventClickHandler(e:any) {
  e.preventDefault();
  e.stopPropagation();
}
