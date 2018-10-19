(function ($) {
    $(function() {
        window.wpOnboardingTourSteps = [
            {
                'next .wp-table--row': I18n.t('js.onboarding.steps.wp_list'),
                'showSkip': false,
                onNext: function () {
                    $(".wp-table--cell-span.id a ")[0].click();
                }
            },
            {
                'next .work-packages-full-view--split-left': I18n.t('js.onboarding.steps.wp_full_view'),
                'showSkip': false,
                'containerClass': '-dark -hidden-arrow'
            },
            {
                'next .work-packages-list-view-button': I18n.t('js.onboarding.steps.wp_back_button'),
                'showSkip': false,
                onNext: function () {
                    $('.work-packages-list-view-button')[0].click();
                }
            },
            {
                'next .add-work-package': I18n.t('js.onboarding.steps.wp_create_button'),
                'showSkip': false,
                'shape': 'circle'
            },
            {
                'next .timeline-toolbar--button': I18n.t('js.onboarding.steps.wp_timeline_button'),
                'showSkip': false,
                'shape': 'circle',
                onNext: function () {
                    $('.timeline-toolbar--button')[0].click();
                }
            },
            {
                'next .work-packages-tabletimeline--timeline-side': I18n.t('js.onboarding.steps.wp_timeline'),
                'showSkip': false,
                'containerClass': '-dark'
            },
            {
                'next .menu-item--help': I18n.t('js.onboarding.steps.help_menu'),
                'shape': 'circle',
                'nextButton': {text: I18n.t('js.onboarding.steps.got_it')},
                'showSkip': false
            }
        ];
    });
}(jQuery))
