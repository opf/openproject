(function ($) {
    $(function() {
        window.wpOnboardingTourSteps = [
            {
                'next .wp-table--row': I18n.t('js.onboarding.steps.wp.list'),
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.next')},
                onNext: function () {
                    $(".inline-edit--display-field.id a ")[0].click();
                }
            },
            {
                'next .work-packages-full-view--split-left': I18n.t('js.onboarding.steps.wp.full_view'),
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.next')},
                'containerClass': '-dark -hidden-arrow'
            },
            {
                'next .work-packages-back-button': I18n.t('js.onboarding.steps.wp.back_button'),
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.next')},
                onNext: function () {
                    $('.work-packages-back-button')[0].click();
                }
            },
            {
                'next .add-work-package': I18n.t('js.onboarding.steps.wp.create_button'),
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.next')},
                'shape': 'circle',
                'timeout': function() {
                    return new Promise(function(resolve) {
                        // We are waiting here for the badge to appear,
                        // because its the last that appears and it shifts the WP create button to the left.
                        // Thus it is important that the tour rendering starts after the badge is visible
                        waitForElement('#work-packages-filter-toggle-button .badge', '#content', function() {
                            resolve();
                        });
                    });
                },
                onNext: function () {
                    $('#wp-view-toggle-button').click();
                }
            },
            {
                'next #wp-view-toggle-button': I18n.t('js.onboarding.steps.wp.timeline_button'),
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.next')},
                'bottom': '-100',
                onNext: function () {
                    $('#wp-view-context-menu .icon-view-timeline')[0].click();
                }
            },
            {
                'next .work-packages-tabletimeline--timeline-side': I18n.t('js.onboarding.steps.wp.timeline'),
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.next')},
                'containerClass': '-dark -hidden-arrow'
            },
            {
                'next .main-menu--arrow-left-to-project': I18n.t('js.onboarding.steps.sidebar_arrow'),
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.next')},
                onNext: function () {
                    $('.main-menu--arrow-left-to-project')[0].click();
                }
            }
        ];
    });
}(jQuery))
