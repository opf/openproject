(function ($) {
    $(function() {
        window.wpOnboardingTourSteps = [
            {
                'next .wp-table--row': I18n.t('js.onboarding.steps.wp_list'),
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.next')},
                onNext: function () {
                    $(".wp-table--cell-span.id a ")[0].click();
                }
            },
            {
                'next .work-packages-full-view--split-left': I18n.t('js.onboarding.steps.wp_full_view'),
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.next')},
                'containerClass': '-dark -hidden-arrow'
            },
            {
                'next .work-packages-list-view-button': I18n.t('js.onboarding.steps.wp_back_button'),
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.next')},
                onNext: function () {
                    $('.work-packages-list-view-button')[0].click();
                }
            },
            {
                'next .add-work-package': I18n.t('js.onboarding.steps.wp_create_button'),
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.next')},
                'shape': 'circle'
            },
            {
                'next .timeline-toolbar--button': I18n.t('js.onboarding.steps.wp_timeline_button'),
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.next')},
                'shape': 'circle',
                onNext: function () {
                    $('.timeline-toolbar--button')[0].click();
                }
            },
            {
                'next .work-packages-tabletimeline--timeline-side': I18n.t('js.onboarding.steps.wp_timeline'),
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
            },
            {
                'next .members-menu-item': I18n.t('js.onboarding.steps.members'),
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.next')},
            },
            {
                'next .wiki-menu--main-item': I18n.t('js.onboarding.steps.wiki'),
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.next')},
            },
            {
                'next .menu-item--help': I18n.t('js.onboarding.steps.help_menu'),
                'shape': 'circle',
                'showSkip': false,
                'nextButton': {text: I18n.t('js.onboarding.buttons.got_it')}
            }
        ];
    });
}(jQuery))
