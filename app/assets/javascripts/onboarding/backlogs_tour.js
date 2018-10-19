(function ($) {
    $(function() {
        window.scrumBacklogsTourSteps = [
            {
                'next #content-wrapper': I18n.t('js.onboarding.steps.backlogs_overview'),
                'showSkip': false,
                'containerClass': '-dark -hidden-arrow'
            },
            {
                'event': 'click',
                'selector': '#sprint_backlogs_container .backlog .menu-trigger',
                'description': I18n.t('js.onboarding.steps.backlogs_task_board_arrow'),
                'showSkip': false,
                'clickable': true,
            },
            {
                'event': 'custom',
                'selector': '.backlog .menu .items',
                'description': I18n.t('js.onboarding.steps.backlogs_task_board_select'),
                'showSkip': false,
                'clickable': true,
                'containerClass': '-dark',
                onBeforeStart: function () {
                    // Handle next step
                    jQuery('.backlog .show_task_board').click(function () {
                        tutorialInstance.trigger('next');
                    });

                    // Disable clicks on the wp context menu links
                    $(".backlog .menu a:not('.show_task_board')").addClass('-disabled').bind('click', preventClickHandler);
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
                'custom .toggler': I18n.t('js.onboarding.steps.wp_toggler'),
                'showSkip': false,
                'shape': 'circle',
                'radius': 20,
                'clickable': true,
                onBeforeStart: function () {
                    waitForElement('.wp-query-menu--item', '.wp-query-menu--results-container', function() {
                        tutorialInstance.trigger('next');
                    });
                }
            },
            {
                "click .wp-query-menu--item[data-category='default']": I18n.t('js.onboarding.steps.wp_query'),
                'showSkip': false,
                'timeout': 200,
                'margin': 0,
                'clickable': true
            }
        ];
    });
}(jQuery))
