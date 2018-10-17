(function ($) {
    $(function() {
        window.homescreenOnboardingTourSteps = [
            {
                'next #top-menu': I18n.t('js.onboarding.steps.welcome'),
                'skipButton': {className: 'enjoyhint_btn-transparent'}
            },
            {
                'description': I18n.t('js.onboarding.steps.project_selection'),
                'selector': '.widget-box.projects',
                'event': 'custom',
                'showSkip': false,
                'containerClass': '-dark',
                'clickable': true,
                onBeforeStart: function () {
                    // Handle next step
                    $('.widget-box.projects a').click(function () {
                        tutorialInstance.trigger('next');
                    });

                    // Disable clicks on the wp context menu links
                    $('.widget-box--blocks--buttons .button').addClass('-disabled').bind('click', preventClickHandler);
                }
            }
        ];
    });
}(jQuery))
