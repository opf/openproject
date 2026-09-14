---
sidebar_navigation:
  title: Resource management
  priority: 989
description: Resource management in OpenProject
keywords: resource management, resources, staff, capacity, capacity planning, key skills, user management 
---

# Resource management with OpenProject

## Introduction

Projects succeed when the right people are available at the right time. Resource management helps organizations understand available capacity, match work with the right skills, and balance workloads across teams and projects.

OpenProject brings resource planning together with project planning and execution in a single platform. Instead of maintaining separate spreadsheets or planning tools, project managers and resource managers can plan capacity, assign work, track progress, and adjust plans as priorities evolve.

If your organization manages many projects simultaneously, **[Portfolio management](../portfolio-management)** provides a strategic overview of projects and initiatives. This use case focuses on the operational side: planning and allocating the people who deliver that work.

## 1. Build the foundation

Resource management starts with understanding who is available, what they can contribute, and how much capacity they have. Successful resource planning depends on accurate organizational information.

Before creating resource plans, configure:

- Departments and organizational structure
- User attributes such as skills, certifications, languages, locations, or areas of expertise
- Working schedules and availability
- Appropriate roles and permissions for project managers, resource managers, and team leads

Keeping this information up to date ensures capacity planning reflects reality rather than assumptions.

### Specify roles and permissions

Before you start planning resources, make sure that appropriate **[roles and permissions](../../system-admin-guide/users-permissions/)** are set up in OpenProject.

Consider who should plan and manage resource allocations, who is responsible for staffing projects, and who needs visibility into capacity across teams and projects. Depending on your organization, these responsibilities might belong to project managers, team leads, resource managers, or other existing roles.

Ensure that each role has the permissions needed for its responsibilities and access to the relevant projects and resource planning features.

> [!TIP]
> Keep responsibilities clear. Decide who can create and adjust resource allocations and who only needs to view capacity and availability.

### Specify organizational structure

Create departments that reflect your organization, such as Engineering, Marketing, Customer Success, or Professional Services.

Navigate to **[System administration → Users and permissions → Organization](../../system-admin-guide/users-permissions/organization/)** to create departments and define your organizational structure.
![Organizational structure in OpenProject showing users grouped into departments](openproject_use_case_admin_organization.png)

Departments can also be added directly to projects and assigned global roles, making it easier to manage access for groups of users.

### Define user attributes and key user skills

Navigate to **[System administration → Users and permissions → User attributes](../../system-admin-guide/users-permissions/user-attributes/)** to create and group attributes that describe your users and help identify suitable people when staffing projects.

For example, you can define attributes for:

- Specific skills
- Certifications
- Languages
- Job titles
- Areas of expertise

![User attributes in OpenProject showing configured skills, languages and job titles](openproject_use_case_user_attributes_list.png)

Add the relevant attributes to individual users and keep this information up to date. Resource managers can then use these attributes as criteria when looking for people who match the requirements of upcoming work.

![OpenProject user profile showing assigned skills and other resource planning attributes](openproject_use_case_user_profile_example.png)

### Configure working schedules and availability

Define each user's working schedule so that resource planning reflects their actual capacity.

Depending on the user's situation, this can include:

- Weekly working hours
- Availability factor
- Planned time off
- Future changes to the working schedule

Planning against effective availability helps create realistic resource plans and identify potential capacity problems before work is assigned.

> [!TIP]
> A person's working hours are not necessarily fully available for project work. Use the availability factor to account for recurring meetings, support duties, administrative work, or other commitments.

![User working schedule in OpenProject showing weekly working hours and availability for project work](openproject_use_case_user_profile_work_schedule_tab.png)

## 2. Set up your project

Before allocating resources, create or open the relevant project and make sure the **Resource management** module is activated under the project settings.

Before allocating resources, define the work that needs to be done. 

Use OpenProject's **[Work packages](../../user-guide/work-packages/)** to break the project down into tasks and plan the desired timeline. At this stage, define the work and target dates. You do not need to know who will perform each task yet, resource requirements and staffing can be planned in the next steps.

For example, imagine you are organizing the **Annual Customer Conference 2026**. Create a project for the conference and add the required activities as work packages, such as defining the event concept, preparing the venue, creating the event website, running the registration campaign, and testing the registration workflow.

Set the planned start and finish dates for these work packages so that the resource requirements can later be evaluated against people's availability.

![Annual Customer Conference 2026 project in OpenProject showing planned work packages and their dates](openproject_use_case_work_packages.png) 

## 3. Plan resource allocations

Once the work and timeline are defined, open the **Resource management** module.

Click **+ Resource planner** to create a planner. Resource planners let you bring together upcoming work, resource requirements, and people's availability so that you can find suitable resources and identify capacity constraints.

For this example, create a **Work packages timeline** planner. Set the time range to cover the relevant project period and filter the planner to show open work packages.

The initial planner displays the work packages and their planned dates, but no resource allocations are shown yet. Warning indicators next to the work packages make it easy to identify work for which resources still need to be planned.

![Resource planner for Annual Customer Conference 2026 showing open work packages without resource allocations](openproject_use_case_resource_planner_no_allocations.png)

### Create a resource allocation

Create an allocation for upcoming work by clicking **+ Allocate** or by selecting the timeline next to a specific work package.

You can allocate:

- A specific user
- A resource based on filter criteria such as role, job title, skills, qualifications, or other user attributes

Using filter criteria is useful when you know **what capabilities you need**, but have not yet decided who should perform the work.

![Create resource allocation dialog in OpenProject with options to select a specific user or define filter criteria](resource-management-planner-allocation-form-options.png)

### Define the resource requirements

For example, the work package **Define event concept and format** requires 12 hours of work between August 10 and August 14.

If you cannot immediately assign a specific person, define the requirements for the resource:

- **Skill:** Event planning
- **Language:** English
- **Language:** French
- **Required capacity:** 12 hours
- **Period:** August 10–14

These criteria are later used to identify users who match the requirements and evaluate their availability.

![Resource request for Define event concept and format requiring event planning skills, English and French language skills, and 12 hours of capacity](resource-management-planner-allocation-form-options-filters.png)

### Review open resource requests

After saving, the allocation appears in the Resource planner as an **open resource allocation request**. It is also available in the **Staffing** view, where open requests can later be matched with suitable people.

This allows you to plan the required capacity before deciding on a specific person. The request remains connected to the work package and its planned time period, making outstanding resource needs visible alongside allocations that have already been staffed.

![Resource planner showing open resource requests in OpenProject resource management module](openproject_use_case_rm_open_allocations.png)

As you add resource allocations, the Resource planner gives you an overview of planned demand. You can see which work already has a specific person allocated and which resource requirements still need to be staffed.

## 4. Staff your projects

Once resource requirements have been planned, use **Staffing** to resolve open resource requests. Click **Staffing** in the left-hand menu to see all current requests.

![Staffing view showing suitable resources for an open resource request](openproject_use_case_rm_staffing_list.png)

Open a resource request to review potential matches. OpenProject automatically matches the requirements defined in the request with your users and shows their availability during the requested period. If a user meets the requirements but does not have enough capacity for the requested hours, a warning indicates the conflict.

Use this information to decide whether to adjust existing allocations, change the requested period or capacity, or select another suitable person. Once you have found the right match, select the user and assign them to the resource request. 

![Staffing view showing suitable resources for an open resource request](openproject_use_case_rm_allocation_details_open.png)

Once the request is staffed, the selected person is added to the resource allocation. Return to the Resource planner to see the updated allocation in the context of the overall project plan.

![Resource planner showing staffed allocations and available capacity](openproject_use_case_resource_planner_allocations.png)

As you staff additional requests, use the Resource planner to identify:

- People who are overallocated
- Remaining capacity
- Resource conflicts
- Work that still needs to be staffed
- Opportunities to redistribute work

## 5. Turn plans into project work

Once resources have been allocated and staffing decisions are made, assign the corresponding work packages to the selected team members.

Work packages remain the central place for managing project execution, including:

- Assigning responsibilities
- Planning dates
- Managing dependencies
- Tracking estimates and remaining work

![A detailed view of a work package, showing assignee, accountable, work estimates](openproject_use_case_rm_wp_detailed_view.png)

## 6. Monitor progress and actual effort

Resource planning is an ongoing process rather than a one-time activity.

As work progresses, team members update their work packages, [report progress](../../user-guide/time-and-costs/progress-tracking/), and [record spent time](../../user-guide/time-and-costs/time-tracking/) where applicable.

Comparing planned capacity with actual effort can help you identify where estimates differ from reality and make more informed resource plans for future work. 

[Time and cost tracking](../..//user-guide/time-and-costs/) and reporting provide additional insights into resource utilization, helping teams identify trends and improve future planning. 

Use these insights when reviewing upcoming allocations and capacity in your Resource planners.

## 7. Review and adjust your resource plans

Projects, priorities, and team availability change over time.

Review your Resource planners regularly to:

- Rebalance workloads
- Resolve overallocation
- Reflect changes in availability
- Staff newly approved work
- Adapt to changing project priorities

Because resource planning, project execution, and reporting are connected, adjustments can be made throughout the project lifecycle without maintaining separate planning tools.

## Outcome

You now have a resource plan that connects project demand with the people and capacity available to deliver it. Resource requirements are visible early, open requests can be matched with suitable people based on their skills and availability, and potential capacity conflicts can be identified before they affect project delivery.

As work progresses, you can review allocations alongside actual effort and changing availability, and adjust your resource plans when priorities, schedules, or staffing needs change.

## Related resources

Resource management works together with several other OpenProject capabilities:

- [**Portfolio management**](../../user-guide/portfolios/) for strategic oversight across projects and initiatives.
- [**Work packages**](../../user-guide/work-packages/) for managing project execution.
- [**Time tracking and costs**](../../user-guide/time-and-costs/time-tracking/)  for analyzing actual effort and utilization.
- [**Progress tracking**](../../user-guide/time-and-costs/progress-tracking/) for monitoring project delivery.

Together, these capabilities support the complete lifecycle from planning capacity to delivering successful projects.

## Summary

Resource management helps organizations match available capacity with project demand. By organizing users, defining availability, planning allocations, staffing projects, assigning work, and reviewing actual effort, teams can make more informed planning decisions and adapt as priorities evolve.

OpenProject connects these activities in a single platform, reducing manual coordination and providing a shared, up-to-date view of people, projects, and capacity. While **Portfolio management** supports strategic decision-making across projects, **Resource management** focuses on ensuring the right people are available to deliver the work successfully.