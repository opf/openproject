(function ($) {
    $(function() {
        // ------------------------------- Global -------------------------------
        window.tutorialInstance;
        window.preventClickHandler = function (e) {
            e.preventDefault();
            e.stopPropagation();
        };
        window.waitForElement = function(element, container, execFunction) {
            // Wait for the element to be ready
            var observer = new MutationObserver(function (mutations, observerInstance) {
                if ($(element).length) {
                    observerInstance.disconnect(); // stop observing
                    execFunction();
                    return;
                }
            });
            observer.observe($(container)[0], {
                childList: true,
                subtree: true
            });
        };
        window.demoProjectName = 'Demo Project';
        window.scrumDemoProjectName = 'Scrum Project';


        var storageKey = 'openProject-onboardingTour';
        var currentTourPart = sessionStorage.getItem(storageKey);
        var url = new URL(window.location.href);

        // ------------------------------- Initial start -------------------------------
        // Do not show the tutorial on mobile
        if(! /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) ) {

            // Start after the intro modal (language selection)
            // This has to be changed once the project selection is implemented
            if (url.searchParams.get("first_time_user") && demoDataVisible()) {
                currentTourPart = '';
                sessionStorage.setItem(storageKey, 'readyToStart');

                // Start automatically when the language selection is closed
                $('.op-modal--modal-close-button').click(function () {
                    homescreenTour();
                });
            }

            // ------------------------------- Tutorial Homescreen page -------------------------------
            if (currentTourPart === "readyToStart") {
                homescreenTour();
            }

            // ------------------------------- Decide for tour depending on backlogs -------------------------------
            if (currentTourPart === "startProjectTour" || url.searchParams.get("start_onboarding_tour")) {
                if ($('.backlogs-menu-item').length > 0) {
                    backlogsTour();
                } else {
                    workPackageTour();
                }
            }

            // ------------------------------- Tutorial Task Board page -------------------------------
            if (currentTourPart === "startTaskBoardTour") {
                taskboardTour();
            }

            // ------------------------------- Tutorial WP page -------------------------------
            if (currentTourPart === "startWpTour") {
                workPackageTour();
            }
        }

        function demoDataVisible() {
            demoProjects = jQuery.grep(jQuery(".widget-box.welcome a"), function( a ) {
                return a.text === demoProjectName || a.text === scrumDemoProjectName;
            });

            return demoProjects.length === 2
        }
        
        function initializeTour(storageValue, disabledElements) {
            tutorialInstance = new EnjoyHint({
                onStart: function () {
                    $('#content-wrapper, #menu-sidebar').addClass('-hidden-overflow');
                },
                onEnd: function () {
                    sessionStorage.setItem(storageKey, storageValue);
                    $('#content-wrapper, #menu-sidebar').removeClass('-hidden-overflow');
                },
                onSkip: function () {
                    sessionStorage.setItem(storageKey, 'skipped');
                    if (disabledElements) jQuery(disabledElements).removeClass('-disabled').unbind('click', preventClickHandler);
                    $('#content-wrapper, #menu-sidebar').removeClass('-hidden-overflow');
                }
            });
        }

        function startTour(steps) {
            tutorialInstance.set(steps);
            tutorialInstance.run();
        }
        
        function homescreenTour() {
            initializeTour('startProjectTour', '.widget-box--blocks--buttons .button');
            startTour(homescreenOnboardingTourSteps);
        }

        function backlogsTour() {
            initializeTour('startTaskBoardTour', ".backlog .menu a:not('.show_task_board')");
            startTour(scrumBacklogsTourSteps);
        }

        function taskboardTour() {
            initializeTour('startWpTour');
            startTour(scrumTaskBoardTourSteps);
        }

        function workPackageTour() {
            initializeTour('wpFinished', '.wp-table--details-link, .wp-table-context-menu-link, .wp-table--cell-span');

            waitForElement('.work-package--results-tbody', '.work-packages-split-view--tabletimeline-side', function() {
                startTour(wpOnboardingTourSteps);
            });
        }
    });
}(jQuery));
