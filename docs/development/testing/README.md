# Testing OpenProject

OpenProject uses automated tests throughout the stack. Tests that are executed in the browser (angular frontend, RSpec system tests) require to have Chrome installed. To ensure we deliver high quality code to our customers, it's essential to conduct various types of tests.

| Topic                                                       | Content                                                      |
| ----------------------------------------------------------- | :----------------------------------------------------------- |
| [Testing architecture](#testing-architecture) (this page)   | Overview of the architecture and involved parties regarding testing |
| [Continuous testing workflow](continuous-testing-workflow/) | Overview of our CI and Continuous testing pipelines and how to debug them |
| [Running tests locally](running-tests-locally/)             | Guides on how to run tests on your machine or on Docker      |
| [Handling flaky tests](handling-flaky-tests/)               | Guides to identify, debug, and fix tests that intermittently pass or fail |

## Testing Architecture

### Involved Roles

Testing OpenProject is distributed between different roles and members, depending on the testing task.

- **Functional testing**: Developer, QA/Tester
- **Non-functional testing**: Developer, QA/Tester, Product manager, Operations engineer
- **Acceptance testing**: Product manager, Designer, QA/Testers, Customers/Community members
- **Usability testing**: UX Designer, Customers, Community members
- **Accessibility testing**: Product team, Developer, External accessibility experts

### Functional testing

Functional testing ensures that the application works against the set of requirements or specifications. Tests should therefore make sure all the acceptance criteria are met.

The following types of functional tests are used at OpenProject.

| **Type**                                                    | Description                                                  | Examples, References                                         |
| ----------------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| [Unit tests](#unit-tests)                                   | Test individual components of OpenProject using RSpec. Involves mocking or stubbing dependent components | e.g, Model specs under `spec/models`                         |
| [Integration tests](#integration-tests)                     | Testing the integration of multiple components, but still in their isolation without testing the entire software stack | controller, requests, service integration specs, e.g., `spec/services/**/*_integration_spec.rb` |
| [Feature / end-to-end tests](#feature-tests)                | Tests of the entire Rails application stack and all necessary dependent components (routing, controllers, database access, permissions, and responses). Performed in `RSpec` using `Capybara` feature specs.<br>External third-party service requests and responses are recorded for testing (e.g., nextcloud integration) | `spec/features`                                              |
| [Smoke tests](#smoke-tests)                                 | Automated and manual tests to ensure the main application features and happy paths are working as expected (e.g., packaging or dockerization tests, manual smoke tests by QA) | Docker test workflow under `.github/workflows/docker.yml`    |
| [Sanity and regression tests](#sanity-and-regression-tests) | Manual testing of affected or relevant components made after changes or bug fixes to the application. Performed by QA. | e.g., testing the critical path of creating work packages after a bug fix has been made in that data model<br>Manual execution of test plan defined by QA |
| [Acceptance tests](#acceptance-tests)                       | Final phase of manual testing where the system is evaluated against predefined requirements to ensure it meets user and stakeholder expectations before deployment. | Manual interactions with customers and stakeholders to identify whether we're building the correct part |

#### Unit tests

Unit testing concerns testing of isolating individual components of the application, such as individual methods within a model, service, or library, in order to verify that they perform as expected under various conditions. OpenProject uses RSpec for writing unit tests / specs.

**Key objectives and effects**

1. **Isolated validation of individual components**: Unit tests isolate the smallest testable parts of an application, often single methods or functions, to validate that they function as intended.
2. **Early defect identification**: Writing and running unit tests before (Test-Driven Development) or during the development phase may help identify bugs early, reducing the cost of fixing them in later stages.
3. **Code quality**: Unit tests shape the development of a component, ensuring that it is testable by reducing coupling between components and by that, improves code quality. Unit tests, when well written, serve as a form of documentation.
4. **Ease of maintenance**: Unit tests in an interpreted language like Ruby make it easier and safer to refactor code, add new features, or integrate new changes with confidence, knowing that existing functionality is well-tested and which functionality breaks when moving code.

**Best practices**

- Follow the Arrange-Act-Assert (AAA) Pattern
  - **Arrange**: Set up the object and scenarios for your test.
  - **Act**: Invoke the method or process you want to test.
  - **Assert**: Check that the method or process behaved as expected.
- Keep examples of unit specs simples and descriptive
- Write tests during or before development, not as an afterthought
- Test the entire range of potential inputs, including _negative_ tests and validation of potentially malicious user input.

  Negative testing consists of test cases which define how software reacts to user’s invalid input or unexpected behavior. The aim is not only to prevent the application from crashing but to improve quality by specifying clear and understandable error messages so that users know what kind of input is expected and correct.
- Avoid calling the database if not necessary
- Use `FactoryBot` to set up test data in a structured, but randomized way to prevent brittle tests
- Mock external components and services, and ensure you test the boundaries of the associated components

**References**

- https://www.browserstack.com/guide/integration-testing
- https://www.codewithjason.com/difference-integration-tests-controller-tests-rails/
- https://guides.rubyonrails.org/testing.html

#### Integration tests

Integration tests focus on the interactions between different components of OpenProject to ensure they work together to deliver a specific functionality. OpenProject uses RSpec to perform integration tests to simulate real-world user behavior. In contrast to system tests, integration tests still leave out some assumptions or characteristics of the application (e.g., not running tests in an instrumented browser instance).

In Rails, the difference between integration tests and feature tests can be blurry. At OpenProject, we assume every test that involves an instrumented browser instance is a _feature spec_. Integration tests can be request or controller specs, or specs in other folders explicitly marked as integration, meaning it will not use mocking to separate the involved components.

**Key objectives and effects**

1. **Verifying interaction of components**: The primary objective of integration testing is to verify that different components or modules of the application work together as intended.
2. **Data integrity and consistency**: Test that data flows correctly between different parts of the application.
3. **API and service dependencies**: For components relying on external APIs and third-party services, integration tests define the boundary between these systems that are often not available in automated test suites. Integration tests for services should include things like proper request formatting and correct handling of all possible response types (success, failure, timeouts, etc.).
4. **Early performance and reliability evaluation**: Integration tests _may_ give an early indication of potential performance issues. Due to the interaction of components, this data flow can identify bottlenecks or inefficiencies that might not be visible during unit testing due to the amount of data mocking present.
5. **Test real interactions**: In Ruby on Rails, unit tests depending on the development style may have the flaw of testing _too_ narrow. With a high amount of mocking, the proper testing and definition of the component's boundary may become blurry and brittle. These problems will only be detectable within integration tests.

**Best practices**

- Mimic user behavior as closely as possible. This means following the paths that users are most likely to take, filling out forms, clicking buttons, etc.
- At the same time, include both successful interactions (happy paths), expected and unexpected failures and edge cases. Align these tests with what is already tested in the relevant unit tests.
- To generate test data, use our defined factories (e.g., FactoryBot) for more complex or dynamic data.
- Be wary of long-running and brittle tests and how to avoid them. Due to the nature of integration tests, execution of tests may be prone to more flickering results when compared to unit tests.
- Know the difference between integration (i.e., requests, controller) tests and system/feature tests and when to use them.

#### Feature tests

Feature tests at OpenProject drive a browser instance to act as if a user was operating the application. This includes logging in, setting session cookies, and navigating/manipulating the browser to interact as the user.

**Key objectives and effects**

1. **End-to-end testing**: Validate the interaction between the entire stack of the application, including the frontend and backend, to ensure they work as expected.

2. **User experience verification**: Simulate real-world user behavior and ensure that the application behaves as expected from a user's perspective.

3. **Increased confidence**: In Rails applications, only feature tests give you the entire picture of the application, especially when frontend code is interacting with the backend.

4. **Responsiveness and compatibility**: Verify that the application's user interface behaves consistently across various browsers, languages, and screen sizes.

**Best practices**

- Happy paths and main errors or permission checks should always be tested with a system test. Avoid testing all edge cases or boundaries using the entire stack, as this will result in slowdown of our CI infrastructure.
- Use Capybara's scoping methods (`within`, `find`, etc.), meaningful selectors, and asynchronous handling to make tests more readable and robust.
- Break down complex user interactions into reusable methods or even separate test cases to make your test suite easier to understand and maintain.
- Keep an eye on flaky tests that fail randomly and fix them, as they can undermine trust in your test suite.
- While frowned upon in unit tests, test the entire use-case in as few examples as possible to avoid additional overhead (starting the browser, loading factories into database etc.). When using multiple examples, use `let_it_be` / `shared_let` and other improvements from the [test-prof gem](https://github.com/test-prof/test-prof)
- Add automated regression tests for bug fixes that are non-trivial

#### Smoke tests

Smoke tests are automated and manual tests to ensure the main application features and happy paths are working as expected. At OpenProject, all installation methods are automatically tested using smoke tests. Packaging processes test all distributions for successful installation of OpenProject. We run the released docker image for setting up and accessing OpenProject.

**Key objectives and effects**

1. **Verify basic functionality**: Perform a quick check to ensure that the most critical functionalities of the application are working as expected.
2. **Find showstoppers**: Identify critical bugs early in the development process before the stabilization phase.
3. **Early feedback**: Provide quick feedback to the development team.

**Best practices**

- Automate smoke testing on top of manual testing when possible
- Run after deployments to the appropriate [environments](../application-architecture/#environments), e.g., the edge environment for features of the next release and staging environment for bug fixes to a stable release
- Keep smoke tests updated so that they can evolve together with the application

**References**

- https://www.browserstack.com/guide/smoke-testing

#### Sanity and regression tests

Sanity and regression tests are manually performed tests by QA for relevant components on a stabilized version, e.g., the developed new features or components of an OpenProject release. A sanity test is a subset of a regression test, which evaluates the entire application prior to a release or production deployment.

**Key objectives and effects**

1. **Proper scoping of the test**: For regression test, QA will evaluate the entire application, executing common use-cases of OpenProject. Sanity tests will instead test a subset of the application, e.g., a specific feature in the process of stabilization.
2. **Change impact**: Identify the impact of new code changes, updates, or bug fixes on the relevant functionality or module of OpenProject.
3. **Confidence**: Increases confidence among stakeholders that new or changed functionalities work as expected.

**Best practices**

- Document test plans for regression tests so that they can be executed easily and new QA employees can be onboarded easily
- Be very selective about what you test for sanity testing. Focus only on the areas that were affected by recent changes
- Stay updated to major code changes so that the regression test plan can be adapted appropriately

**Usage at OpenProject**

For writing and executing manual sanity and regression testing, especially focusing on functional requirements, one of the tools in use at OpenProject is [TestLink](https://testlink.org/) to achieve the following goals:

- Test cases have clear preconditions so that the tester prepares for executing each case with enough knowledge about requirements.
- Test cases are as specific as possible. They should check the proper working of one single point/case and should therefore have no more than 8-10 steps.
- Test cases are updated with every change of the specifications.
- Test cases have precise execution steps and expected results.

**References**

- https://www.browserstack.com/guide/sanity-testing
- https://www.browserstack.com/guide/regression-testing
- https://medium.com/@Jia_Le_Yeoh/difference-between-regression-sanity-and-smoke-testing-ed2129bf049

#### Acceptance tests

Acceptance testing is the final phase of testing where the extension to the OpenProject application is evaluated against predefined requirements to ensure it meets user and stakeholder expectations before deployment.

Acceptance tests evaluate both functional and non-functional requirements.

**Key objectives and effects**

1. **Validation of requirements**: Ensure that the defined feature / change meets all specified requirements, as outlined by the stakeholders and defined by the product team.
2. **Reduced risk**: Identify and reduce risk of releasing a product that doesn't meet user expectations or contractual obligations.
3. **Contractual closure**: May act as a formal sign-off before the software goes live, signifying that it has met agreed-upon criteria.
4. **System behavior**: Confirm that all features and functionalities behave as expected in real-world scenarios.
5. **Data integrity and workflow**: Verify the end-to-end processes, and ensure data consistency and integrity throughout the system.

**Best practices**

1. Ensure customer provided user stories and acceptance criteria is well defined before development phase is entered, or be clear and open about the scope of what is to be built.
2. Perform acceptance test in an environment that mimics the production environment as closely as possible. This could be an isolated edge environment, or a separately deployed instance at the customer's request.
3. Maintain clear and detailed documentation of test cases, outcomes, and any _discrepancies_ between expected and actual implementation and results.

### Non-functional testing

Non-functional testing goes beyond the functionality of the product and is aimed at end-user experience. Test cases should hence make sure to define what is expected in terms of security, performance, compatibility, accessibility etc.

Examples for non-functional test cases: software should be compatible with most used desktop and mobile browsers, as well as operating systems; all the actions can be performed with keyboard navigation; page loading should take no more than X seconds; users who lost access should no longer be able to login etc.

| Type                                                            | Description                                                                                                                                                                                   | Examples, References                                                                                                                                                                       |
|-----------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Stress and performance tests](#performance-tests)              | (Half-)automated or manual testing of the response of the application during higher load, or expected upper boundaries of customer-defined data                                               | e.g., running and evaluating new query plans on existing, anonymized or simulated data that matches potential or known performance bottlenecks                                             |
| [Security tests](#security-tests)                               | Automated or manually crafted test cases for evaluating application security by assuming the role of an attacker, e.g., by providing malicious user input or trying to break the application. | Statical and automated code scanning (CodeQL, Brakeman), defined test cases for verifying security related input as defined in the [secure coding guidelines](../concepts/secure-coding/). |
| [Installation / upgrade tests](#installation-and-upgrade-tests) | Automated and manual installation tests of OpenProject                                                                                                                                        | Packaged installation build tests for various distributions, Docker installation smoke tests for verifying correct startup and basic operation of the container.                           |
| [Usability tests](#usability-testing)                           | Evaluating the UX of the application as defined and in comparison to the requirements. Involves QA, Product, Customer.                                                                        | e.g., verifying common use-cases as defined in the requirements in an early development stage (such as a PullPreview deployment), or on a pre-released version of the application.         |
| [Accessibility tests](#accessibility-tests)                     | Evaluating the accessibility of the application according to [WCAG AA](https://www.w3.org/WAI/WCAG2AA-Conformance) and similar standards                                                      | Performing automated keyboard navigation tests. <br>Manually executing screen readers to ensure application can be used.                                                                 |

#### Performance tests

Identify and prevent common causes of bottlenecks in the application. As OpenProject is a software where a lot of information might come together and presented in a very flexible manner, performance is an ever-present concern and consideration for the developers.

**Key objectives and effects**

1. **Reliability**: Improve the reliability of the application by identifying bottlenecks and performance issues.
2. **Stress testing**: Identify the limits and the breaking points of the application.
3. **User satisfaction**: Ensure that users have a good experience for common use-cases.

**Best practices**

- Include performance tests, automated or manual, in the development of every feature that involves moving a lot of user data
- Use appropriate data for the tests, this could be anonymized or prepared data provided by customers or through statically or manually provided factories.
- Establish a performance baseline so that you can compare how code changes impact performance over time.
- OpenProject implements monitoring tools for SaaS applications to monitor performance and identify bottlenecks.

#### Security tests

Automated or manual security tests for OpenProject are evaluating common weaknesses of web applications and follow the best practices of the [secure coding guidelines](../concepts/secure-coding/).

**Key objectives and effects**

1. **Vulnerability assessment**: Identify and prevent common security vulnerabilities in the application, such as SQL injection, CSRF, and XSS vulnerabilities.
2. **Authentication and authorization tests**: Ensure that authentication mechanisms are robust and that only authorized users can access sensitive features.
3. **Risk mitigation**: Early identification of security vulnerabilities helps mitigate risks associated with data breaches and unauthorized access.
4. **Audit and compliance**: Ensure that the application complies with internal security guidelines, as well as any industry-specific security standards.

**Best practices**

- Use statical and dynamical code analysis for automated vulnerability testing. OpenProject uses CodeQL and Brakeman as part of the CI pipeline to give early feedback to common vulnerabilities.
- OpenProject uses [Docker Scout](https://www.docker.com/products/docker-scout/) for the Docker images hosted on Docker Hub for automated vulnerability scanning and analysis of the built container, including all dependencies. The scan is using Vulnerability Exploitability eXchange (VEX). Every image [is being published with vulnerability attestations](../concepts/secure-coding/#packaging-and-containerization) so that information about vulnerabilities that actually affect OpenProject is included.
- Follow our [secure coding guidelines](../concepts/secure-coding/) when proposing changes to the application, especially when modifying or adding features to authentication, authorization, 2FA, or sensitive data operations.
- If possible, automate security tests for common vulnerabilities for input in your development.
- Train on recent vulnerabilities and checklists such as [OWASP Top Ten](https://owasp.org/www-project-top-ten/) or [OWASP cheat sheets](https://cheatsheetseries.owasp.org) to stay up-to-date on security testing and extend our security test suite with new information.

#### Installation and upgrade tests

OpenProject employs a number of automated tests for installation testing. Packaged installation build tests for various distributions, Docker installation smoke tests for verifying correct startup and basic operation of the container.

Upgrade tests are manually performed for major code changes and data migrations on pre-release candidates to ensure migrations are working as expected. The [OpenProject Community](https://community.openproject.org) instance also serves as an early release candidate to allow early testing and feedback.

**Key objectives and effects**

1. **Verify seamless installation**: Ensure that OpenProject can be installed as documented.
2. **Correct and minimal configuration:** Ensure that the default configuration is minimal but sufficient to operate OpenProject securely, and check that the required necessary configuration is minimal. New configuration primitives should receive a secure default.
3. **Check version compatibility**: Test the compatibility of the upgraded application with existing configurations, databases, and other dependent software.
4. **Validate migrations**: Confirm that during an upgrade, data migration occurs without data loss or corruption.
5. **Technical support**: Reduce the number of support tickets related to installation and upgrade issues.
6. **Operational efficiency**: Minimize downtime and service interruptions during the upgrade process.

**Best practices**

- Use automated testing scripts to simulate various installation and upgrade scenarios.
- Provide and test the rollback of data migrations to make sure they work as intended.
- Keep up-to-date documentation for the installation and upgrade procedures, including a list of known issues and workarounds.
- Example of test cases would be ensuring that software works in a satisfying manner on major browsers and operating systems which are defined in [system-requirements](../../installation-and-operations/system-requirements/)

#### Usability testing

When new features or changes to the application are available on our [Edge or Community environments](../application-architecture/#environments), product team members, customers, and community users can provide usability feedback on how the change is perceived.

**Key objectives and effects**

1. **User-friendliness**: Evaluate how easily end-users can navigate and perform tasks within the application, focusing on intuitiveness and accessibility.

2. **Increased user satisfaction and adoption**: Better usability promotes a higher rate of user adoption and lowers abandonment rates.

3. **Error handling and messages**: Assess the software's ability to prevent, catch, and handle errors in a way that is informative and non-intrusive for the user.

4. **Consistency and standards**: Ensure that the application's UI and functionality conform to common design and usability standards, promoting user familiarity.

5. **Reduced support costs**: Intuitive and user-friendly designs decrease the volume of help desk or support questions.

**Best practices**

- Involve actual users in requirements and usability feedback to collect genuine user insights.
- Perform usability feedback rounds at multiple stages of development to continuously refine the user experience and ensure we're building the correct things.
- **Real-world scenarios**: Test the application by simulating real-world tasks and scenarios that a typical user would encounter.
- **Quantitative and qualitative metrics**: Use a mix of metrics like task completion rates, error rates, and user satisfaction surveys to comprehensively assess usability.

#### Accessibility tests

OpenProject strives to be accessible for all users while also retaining a high usability. In web applications, these two requirements can sometimes be a seemingly contradictory requirement, especially when animations or _modern_ functionalities of browsers are used.

**Key objectives and effects**

1. **Compliance with WCAG**: Standards exists to ensure and implement means of accessible interactions for all users.
2. **Universal usability**: Application is functional and provides a good user experience for people with disabilities, including those who use assistive technologies.
3. **Text-to-Speech and Speech-to-Text**: Compatibility with screen readers and voice-command software to assist visually impaired and mobility-challenged users.
4. **Navigational ease**: Application can be effectively navigated using only a keyboard, without requiring a mouse.
5. **Contrast and readability**: Test text contrast, size, and spacing to ensure readability for users with visual impairments.

**Best practices**

1. Make accessibility testing an integral part of the development lifecycle, starting with the requirements.
2. Use specialized browser extension to help identify and resolve common accessibility issues.
3. Follow the best practices of the [WCAG 2 checklists](https://www.w3.org/WAI/WCAG22/quickref/) and [accessibility patterns](https://www.w3.org/WAI/ARIA/apg/patterns/) from ARIA authoring practices guide to ensure screen readers and other assistive technologies are well supported.
4. Use [axe-core for RSpec](https://github.com/dequelabs/axe-core-gems/blob/develop/packages/axe-core-rspec/README.md) in automated accessibility tests to provide continuous regression testing against common accessibility issues.
5. Use [capybara-accessible-selectors](https://github.com/citizensadvice/capybara_accessible_selectors) in [feature tests](#feature-tests) to find UI elements using screen-reader compatible selectors. This ensures the page elements used by feature tests are accessible to assistive technologies.
6. Consult with accessibility experts to conduct audits and provide recommendations for improvements. Alternatively, consult the development colleagues with experience in accessibility testing to evaluate requirements and implementation proposals.

**References**

- https://www.deque.com/axe/browser-extensions/
- https://www.w3.org/WAI/WCAG22/quickref/
- https://www.w3.org/WAI/ARIA/apg/patterns/
- https://github.com/dequelabs/axe-core-gems/blob/develop/packages/axe-core-rspec/README.md
- https://github.com/citizensadvice/capybara_accessible_selectors
