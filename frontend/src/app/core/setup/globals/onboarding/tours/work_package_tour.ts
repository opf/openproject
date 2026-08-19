import { waitForElement } from 'core-app/core/setup/globals/onboarding/helpers';
import { OnboardingStep } from 'core-app/core/setup/globals/onboarding/onboarding_tour';

export function wpOnboardingTourSteps():OnboardingStep[] {
  return [
    {
      'next .add-work-package': I18n.t('js.onboarding.steps.wp.create_button'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      shape: 'circle',
      timeout: () => new Promise((resolve) => {
        // We are waiting here for the badge to appear,
        // because it's the last that appears and it shifts the WP create button to the left.
        // Thus it is important that the tour rendering starts after the badge is visible
        waitForElement('#work-packages-filter-toggle-button .badge', '#content', () => {
          resolve(undefined);
        });
      })
    },
    {
      'next .wp-table--row': I18n.t('js.onboarding.steps.wp.list'),
      showSkip: false,
      nextButton: { text: I18n.t('js.onboarding.buttons.next') },
      onNext() {
        const firstId = document.querySelectorAll('.inline-edit--display-field.id a ')[0].innerHTML;
        window.location.href = `${window.location.origin}/projects/demo-project/work_packages/${firstId}/activity`;
      },
    }
  ];
}
