import { demoProjectName, preventClickHandler, scrumDemoProjectName } from "core-app/globals/onboarding/helpers";

export function homescreenOnboardingTourSteps() {
  return [
    {
      'next #top-menu': I18n.t('js.onboarding.steps.welcome'),
      'skipButton': { className: 'enjoyhint_btn-transparent', text: I18n.t('js.onboarding.buttons.skip') },
      'nextButton': { text: I18n.t('js.onboarding.buttons.next') },
      'containerClass': '-hidden-arrow',
      'bottom': 7
    },
    {
      'description': I18n.t('js.onboarding.steps.project_selection'),
      'selector': '.widget-box.welcome',
      'event': 'custom',
      'showSkip': false,
      'containerClass': '-dark -hidden-arrow',
      'clickable': true,
      onBeforeStart: function () {
        // Handle the correct project selection and redirection
        // This will be removed once the project selection is implemented
        jQuery(".widget-box.welcome a:contains(" + scrumDemoProjectName + ")").click(function (this:HTMLAnchorElement) {
          window.onboardingTourInstance.trigger('next');
          window.location.href = this.href + '/backlogs/?start_scrum_onboarding_tour=true';
        });
        jQuery(".widget-box.welcome a:contains(" + demoProjectName + ")").click(function (this:HTMLAnchorElement) {
          window.onboardingTourInstance.trigger('next');
          window.location.href = this.href + '/work_packages/?start_onboarding_tour=true';
        });
        // Disable clicks on other links
        jQuery('.widget-box.welcome a').addClass('-disabled').bind('click', preventClickHandler);
      }
    }
  ];
}
