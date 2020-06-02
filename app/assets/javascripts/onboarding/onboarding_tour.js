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
        window.demoProjectName = 'Demo project';
        window.scrumDemoProjectName = 'Scrum project';

        var storageKey = 'openProject-onboardingTour';
        var currentTourPart = sessionStorage.getItem(storageKey);
        var url = new URL(window.location.href);
        var isMobile = document.body.classList.contains('-browser-mobile');
        var demoProjectsAvailable = $('meta[name=demo_projects_available]').attr('content') === "true";
        var boardsDemoDataAvailable = $('meta[name=boards_demo_data_available]').attr('content') === "true";
        var eeTokenAvailable = !$('body').hasClass('ee-banners-visible');
        var tourCancelled = false;

        // ------------------------------- Initial start -------------------------------
        // Do not show the tutorial on mobile or when the demo data has been deleted
        if(!isMobile && demoProjectsAvailable) {

            // Start after the intro modal (language selection)
            // This has to be changed once the project selection is implemented
            if (url.searchParams.get("first_time_user") && demoProjectsLinks().length == 2) {
                currentTourPart = '';
                sessionStorage.setItem(storageKey, 'readyToStart');

                // Start automatically when the language selection is closed
                $('.op-modal--modal-close-button').click(function () {
                    tourCancelled = true;
                    homescreenTour();
                });

                //Start automatically when the escape button is pressed
                document.addEventListener('keydown', function(event) {
                    if (event.key == "Escape" && !tourCancelled) {
                        tourCancelled = true;
                        homescreenTour();
                    }
                }, { once: true });
            }

            // ------------------------------- Tutorial Homescreen page -------------------------------
            if (currentTourPart === "readyToStart") {
                homescreenTour();
            }

            // ------------------------------- Tutorial WP page -------------------------------
            if (currentTourPart === "startMainTourFromBacklogs" || url.searchParams.get("start_onboarding_tour")) {
                mainTour();
            }

            // ------------------------------- Tutorial Backlogs page -------------------------------
            if (url.searchParams.get("start_scrum_onboarding_tour")) {
                if ($('.backlogs-menu-item').length > 0) {
                    backlogsTour();
                }
            }

            // ------------------------------- Tutorial Task Board page -------------------------------
            if (currentTourPart === "startTaskBoardTour") {
                taskboardTour();
            }
        }

        function demoProjectsLinks() {
            demoProjects = [];
            demoProjectsLink = jQuery(".widget-box.welcome a:contains(" + demoProjectName + ")");
            scrumDemoProjectsLink = jQuery(".widget-box.welcome a:contains(" + scrumDemoProjectName + ")");
            if (demoProjectsLink.length) demoProjects.push(demoProjectsLink);
            if (scrumDemoProjectsLink.length) demoProjects.push(scrumDemoProjectsLink);

            return demoProjects;
        }
        
        function initializeTour(storageValue, disabledElements, projectSelection) {
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
                    if (projectSelection) $.each(demoProjectsLinks(), function(i, e) { $(e).off('click')});
                    $('#content-wrapper, #menu-sidebar').removeClass('-hidden-overflow');
                }
            });
        }

        function startTour(steps) {
            tutorialInstance.set(steps);
            tutorialInstance.run();
        }
        
        function homescreenTour() {
            initializeTour('startProjectTour', '.widget-box--blocks--buttons a', true);
            startTour(homescreenOnboardingTourSteps);
        }

        function backlogsTour() {
            initializeTour('startTaskBoardTour');
            startTour(scrumBacklogsTourSteps);
        }

        function taskboardTour() {
            initializeTour('startMainTourFromBacklogs');
            startTour(scrumTaskBoardTourSteps);
        }

        function mainTour() {
            initializeTour('mainTourFinished');

            waitForElement('.work-package--results-tbody', '#content', function() {
                var steps;

                // Check for EE edition, and available seed data of boards.
                // Then add boards to the tour, otherwise skip it.
                if (eeTokenAvailable && boardsDemoDataAvailable) {
                    steps = wpOnboardingTourSteps.concat(boardTourSteps).concat(menuTourSteps);
                } else {
                    steps = wpOnboardingTourSteps.concat(menuTourSteps);
                }

                startTour(steps);
            });
        }
    });
}(jQuery));
