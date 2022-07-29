---
sidebar_navigation:
title: Contracted services description: An introduction to services and contracts for manipulating data. robots: index,
follow keywords: services, contracts, contracted, validations, validate, create, updated, delete, destroy
---

# OpenProject's concept of Services and Contracts

Creating, updating and deleting data is a very normal task in any application. And a framework like Ruby on Rails
already helps us a lot to make it as easy as possible. However, at OpenProject we decided to move all business logic for
data manipulation to separate services. Further we enhance these services with contracts that specify what are allowed
and valid manipulations. The benefits are

- Reusability: Don't repeat yourself when doing the same manipulation again and again. For example, a service for
  creating a work package could get used when implementing an API endpoint but also in plain old Ruby controllers. Also,
  when we already implement services and contracts creating an API endpoint for that resource becomes very easy. More
  about that later.
- Testability: It is much easier to test single classes that just have one purpose.
- Validation: Extracting validations to a single class concentrates all logic in a single place and thus is much easier
  to test than if the validations were only in the ActiveRecord model.
- Explicit side effects: Don't get into "callback hell" on ActiveRecord models anymore and be explicit what side effects
  you want to achieve. For example, deleting all attachments from some storage when deleting a work package or project
  becomes explicit and not hidden in some hook or callback.

## Fat models and fat controllers become hard to understand and change

Controllers and models become fat and nobody understands them anymore.

Extract everything from controllers and models so that they become very thin and easy to understand and to test.

Put every logic that is needed for manipulating data into services and contracts.

Using services and contracts we get a clean and trust worthy interface for manipulating data. It becomes super cheap and
predictable to use them in other places.

To get from normal Ruby on Rails controllers, helpers and models to services and contracts, just follow the 5 simple
steps.

## How to refactor a Rails controllers, helpers and models to OpenProject's services and contracts

- Extract permission checking from controllers and helpers into a contract.
- Extract validations from the model and put them into a contract.
- Extract all side effects from controllers and models into a service.
- Create separate specs for services and controllers.
- Simplify specs for controllers and models by heavily mocking
- Make sure you have some integration test, i.e. feature spec or request spec, covering basic happy paths for create,
- update and delete operations.

## Identify everything in your controllers and models that is used for permission validations 
