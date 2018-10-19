(function ($) {
    $(function() {
        window.scrumBacklogsTourSteps = [
            {
                'next #content-wrapper': I18n.t('js.onboarding.steps.backlogs_overview'),
                'showSkip': false,
                'containerClass': '-dark -hidden-arrow'
            },
            {
                'event_type': 'next',
                'selector': '#sprint_backlogs_container .backlog .menu-trigger',
                'description': I18n.t('js.onboarding.steps.backlogs_task_board_arrow'),
                'showSkip': false,
                onNext: function () {
                    $('#sprint_backlogs_container .backlog .menu-trigger')[0].click();
                }
            },
            {
                'event_type': 'next',
                'selector': '#sprint_backlogs_container .backlog .menu .items',
                'description': I18n.t('js.onboarding.steps.backlogs_task_board_select'),
                'showSkip': false,
                'containerClass': '-dark',
                onNext: function () {
                    $('#sprint_backlogs_container .backlog .show_task_board')[0].click();
                }
            }
        ];

        window.scrumTaskBoardTourSteps = [
            {
                'next #content-wrapper': I18n.t('js.onboarding.steps.backlogs_task_board'),
                'showSkip': false,
                'containerClass': '-dark -hidden-arrow'
            },
            {
                'next .toggler': I18n.t('js.onboarding.steps.wp_toggler'),
                'showSkip': false,
                'shape': 'circle',
                onNext: function () {
                    $('#main-menu-work-packages-wrapper .toggler').click();
                }
            },
            {
                "next .wp-query-menu--item[data-category='default']": I18n.t('js.onboarding.steps.wp_query'),
                'showSkip': false,
                'timeout': 200,
                onNext: function () {
                    $(".wp-query-menu--item[data-category='default'] .wp-query-menu--item-link")[0].click();
                }
            }
        ];
    });
}(jQuery))
