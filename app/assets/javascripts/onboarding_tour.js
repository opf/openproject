(function ($) {
    $(function() {
        var preventClickHandler = function(e) {
            e.preventDefault();
            e.stopPropagation();
        };
        var storageKey = 'openProject-onboardingTour';
        var currentTourPart = sessionStorage.getItem(storageKey);
        var url = new URL(window.location.href);
        var tutorialInstance;

        var homescreenOnboardingTourSteps = [
            {
                'next #top-menu' : I18n.t('js.onboarding.steps.welcome')
            },
            {
                'description' : I18n.t('js.onboarding.steps.project_selection'),
                'selector' : '.widget-box.projects',
                'event' : 'custom',
                'showSkip' : false,
                'containerClass' : '-dark',
                'clickable' : true,
                onBeforeStart: function(){
                    // Handle next step
                    $('.widget-box.projects a').click(function() {
                        tutorialInstance.trigger('next');
                    });

                    // Disable clicks on the wp context menu links
                    $('.widget-box--blocks--buttons .button').addClass('-disabled').bind('click', preventClickHandler);
                }
            }
        ];

        var overviewOnboardingTourSteps = [
            {
                'next #content' : I18n.t('js.onboarding.steps.project_overview'),
                'showSkip' : false,
                'containerClass' : '-dark'
            },
            {
                'next #menu-sidebar' : I18n.t('js.onboarding.steps.sidebar'),
                'showSkip' : false
            },
            {
                'next .settings-menu-item' : I18n.t('js.onboarding.steps.settings'),
                'showSkip' : false
            },
            {
                'next .members-menu-item' : I18n.t('js.onboarding.steps.members'),
                'showSkip' : false
            },
            {
                'click .toggler' : I18n.t('js.onboarding.steps.wp_toggler'),
                'showSkip' : false,
                'shape' : 'circle',
                'radius' : 20,
                'clickable' : true
            },
            {
                "click .wp-query-menu--item[data-category='default']": I18n.t('js.onboarding.steps.wp_query'),
                'showSkip' : false,
                'timeout' : 200,
                'margin' : 0,
                'clickable' : true
            }
        ];

        var scrumOverviewOnboardingTourSteps = [
            {
                'next #content' : I18n.t('js.onboarding.steps.project_overview'),
                'showSkip' : false,
                'containerClass' : '-dark'
            },
            {
                'next #menu-sidebar' : I18n.t('js.onboarding.steps.sidebar'),
                'showSkip' : false
            },
            {
                'next .settings-menu-item' : I18n.t('js.onboarding.steps.settings'),
                'showSkip' : false
            },
            {
                'next .members-menu-item' : I18n.t('js.onboarding.steps.members'),
                'showSkip' : false
            },
            {
                'click .backlogs-menu-item' : I18n.t('js.onboarding.steps.backlogs'),
                'showSkip' : false,
                'margin' : 0,
                'clickable' : true
            }
        ];

        var scrumBacklogsTourSteps = [
            {
                'next #content' : I18n.t('js.onboarding.steps.backlogs_overview'),
                'showSkip' : false,
                'containerClass' : '-dark'
            },
            {
                'event' : 'click',
                'selector' : '.backlog .menu-trigger',
                'description' : I18n.t('js.onboarding.steps.backlogs_task_board_arrow'),
                'showSkip' : false,
                'clickable' : true,
            },
            {
                'event' : 'custom',
                'selector' : '.backlog .menu .items',
                'description' : I18n.t('js.onboarding.steps.backlogs_task_board_select'),
                'showSkip' : false,
                'clickable' : true,
                'containerClass' : '-dark',
                onBeforeStart: function(){
                    // Handle next step
                    jQuery('.backlog .show_task_board').click(function() {
                        tutorialInstance.trigger('next');
                    });

                    // Disable clicks on the wp context menu links
                    $(".backlog .menu a:not('.show_task_board')").addClass('-disabled').bind('click', preventClickHandler);
                }
            }
        ];

        var scrumTaskBoardTourSteps = [
            {
                'next #content' : I18n.t('js.onboarding.steps.backlogs_task_board'),
                'showSkip' : false,
                'containerClass' : '-dark'
            },
            {
                'click .toggler' : I18n.t('js.onboarding.steps.wp_toggler'),
                'showSkip' : false,
                'shape' : 'circle',
                'radius' : 20,
                'clickable' : true
            },
            {
                "click .wp-query-menu--item[data-category='default']": I18n.t('js.onboarding.steps.wp_query'),
                'showSkip' : false,
                'timeout' : 200,
                'margin' : 0,
                'clickable' : true
            }
        ];

        var wpOnboardingTourSteps = [
            {
                'custom .wp-table--row' : I18n.t('js.onboarding.steps.wp_list'),
                'showSkip' : false,
                'margin' : 5,
                'clickable' : true,
                onBeforeStart: function(){
                    // Handle next step
                    $('.wp-table--row ').dblclick(function(e) {
                        if (!$(e.target).hasClass('wp-edit-field--display-field')) tutorialInstance.trigger('next');
                    });
                    $('.wp-table--cell-td.id a').click(function() {
                        tutorialInstance.trigger('next');
                    });

                    // Disable clicks on the wp context menu links
                    $('.wp-table--details-link, .wp-table-context-menu-link, .wp-table--cell-span').addClass('-disabled').bind('click', preventClickHandler);
                }
            },
            {
                'next .work-packages-full-view--split-left' : I18n.t('js.onboarding.steps.wp_full_view'),
                'showSkip' : false,
                'containerClass' : '-dark'
            },
            {
                'click .work-packages-list-view-button' : I18n.t('js.onboarding.steps.wp_back_button'),
                'showSkip' : false,
                'clickable' : true
            },
            {
                'next .add-work-package' : I18n.t('js.onboarding.steps.wp_create_button'),
                'showSkip' : false,
                'shape' : 'circle'
            },
            {
                'click .timeline-toolbar--button' : I18n.t('js.onboarding.steps.wp_timeline_button'),
                'showSkip' : false,
                'shape' : 'circle',
                'clickable' : true
            },
            {
                'next .work-packages-tabletimeline--timeline-side' : I18n.t('js.onboarding.steps.wp_timeline'),
                'showSkip' : false,
                'containerClass' : '-dark'
            },
            {
                'next .menu-item--help' : I18n.t('js.onboarding.steps.help_menu'),
                'shape' : 'circle',
                "nextButton" : {text: I18n.t('js.onboarding.steps.got_it')},
                'showSkip' : false
            }
        ];

        // Start after the intro modal (language selection)
        // This has to be changed once the project selection is implemented
        if(url.searchParams.get("first_time_user")) {
            currentTourPart = '';
            sessionStorage.setItem(storageKey, 'readyToStart');

            // Start automatically when the language selection is closed
            $('.op-modal--modal-close-button').click(function() {
                initializeTour('startOverviewTour', '.widget-box--blocks--buttons .button');
                startTour(homescreenOnboardingTourSteps);
            });
        }

        // ------------------------------- Tutorial Homescreen page -------------------------------
        if (currentTourPart === "readyToStart") {
            initializeTour('startOverviewTour', '.widget-box--blocks--buttons .button');
            startTour(homescreenOnboardingTourSteps);
        };

        // ------------------------------- Tutorial Overview page -------------------------------
        if (currentTourPart === "startOverviewTour") {
            if($('.backlogs-menu-item').length > 0) {
                initializeTour('startBacklogsTour');
                startTour(scrumOverviewOnboardingTourSteps);
            } else {
                initializeTour('startWpTour');
                startTour(overviewOnboardingTourSteps);
            }
        };

        // ------------------------------- Tutorial Backlogs page -------------------------------
        if (currentTourPart === "startBacklogsTour") {
            initializeTour('startTaskBoardTour', ".backlog .menu a:not('.show_task_board')");
            startTour(scrumBacklogsTourSteps);
        };

        // ------------------------------- Tutorial Backlogs page -------------------------------
        if (currentTourPart === "startTaskBoardTour") {
            initializeTour('startWpTour');
            startTour(scrumTaskBoardTourSteps);
        };

        // ------------------------------- Tutorial WP page -------------------------------
        if (currentTourPart === "startWpTour") {
            initializeTour('wpFinished', '.wp-table--details-link, .wp-table-context-menu-link, .wp-table--cell-span');

            // Wait for the WP table to be ready
            var observer = new MutationObserver(function (mutations, observerInstance) {
                if ($('.work-package--results-tbody')) {
                    observerInstance.disconnect(); // stop observing

                    startTour(wpOnboardingTourSteps);
                    return;
                }
            });
            observer.observe($('.work-packages-split-view--tabletimeline-side')[0], {
                childList: true,
                subtree: true
            });

        }

        function initializeTour(storageValue, disabledElements) {
            tutorialInstance = new EnjoyHint({
                onEnd: function () {
                    sessionStorage.setItem(storageKey, storageValue);
                },
                onSkip: function () {
                    sessionStorage.setItem(storageKey, 'skipped');
                    if (disabledElements) jQuery(disabledElements).removeClass('-disabled').unbind('click', preventClickHandler);
                }
            });

        }

        function startTour(steps) {
            tutorialInstance.set(steps);
            tutorialInstance.run();
        }
    });
}(jQuery));
