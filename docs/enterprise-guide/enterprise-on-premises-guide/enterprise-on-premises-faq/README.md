---
sidebar_navigation:
  title: Enterprise on-premises FAQ
  priority: 001
description: Frequently asked questions regarding Enterprise on-premises
robots: index, follow
keywords: Enterprise on-premises FAQ, enterprise edition, self-hosted
---


# Frequently asked questions (FAQ) for Enterprise on-premises


## How can I upgrade to the OpenProject Enterprise on-premises edition?

The Enterprise on-premises edition is an upgrade of the self-hosted Community Edition. When you are already using the Community Edition, you can purchase an Enterprise on-premises edition license to upgrade to the Enterprise on-premises edition. To do this, follow these steps:

1. Navigate to https://www.openproject.org/enterprise-edition/.
2. Click on the "Book now" button.
3. Follow the steps to purchase the Enterprise on-premises edition license. You will then receive an Enterprise on-premises edition license key by email which you can use to upgrade your Community Edition to the Enterprise on-premises edition. 

If you prefer to test the Enterprise on-premises edition before purchasing, you can request a 14 day trial license from within your system (*Administration -> Enterprise Edition*). Simply click on the green **Start free trial** button to receive a 14 day trial license. If you like the premium features and want to continue, you can easily book the Enterprise on-premises version via the Enterprise Edition menu in the Administration. Otherwise, you will automatically be downgraded to the Community Edition. 

You will keep your data during the whole process.

Find more information [here](https://www.openproject.org/blog/enterprise-edition-upgrade-test-free/).

## How can I book additional users?

Please use the link "Manage subscription" in the email you received confirming your subscription or contact sales@openproject.com. 

## Is it possible to only upgrade *some* users to the Enterprise Edition?

This is not possible, as the Premium features affect the whole OpenProject instance and not the individual users.

## I didn't receive my license key / Enterprise token

The Enterprise token is sent to the email address used to create the subscription. If you can't find it in the spam folder and if you already paid for the subscription please contact support.

## Can I use my own domain name?

Yes, for Enterprise on-premises and for Community Edition you will have to choose your own domain name during [initial configuration](../../../installation-and-operations/installation/packaged/#initial-configuration) after installing OpenProject.

## How can I change my payment details (e.g. new credit card)?

Please use the link "Manage subscription" in the first email you received from our system. Alternatively, please contact support via email.

## How can I downgrade from Enterprise Edition to Community Edition?

You don't have to do anything. Just don't renew your subscription. As soon as your subscription or your trial ends you will automatically be downgraded to the Community Edition. You can keep your data.

## I can't login via SSO to update my Enterprise on-premises token. What do I do?

Until this issue is fixed you can set the token manually via the console. Copy the new token and then do the following.

```
sudo openproject run console
# if user the docker all-in-one container: docker exec -it openproject bundle exec rails console
# if using docker-compose: docker-compose run --rm web bundle exec rails console
```
Once in the console update the token like this:
`EnterpriseToken.first.update encoded_token: "..."`
Where `...` is the token you have copied earlier.
After that you can quit the console by entering `exit`.


## Do you have a reseller program for OpenProject?

We provide a [reseller program](https://www.openproject.org/reseller-program/) exclusively for OpenProject Enterprise on-premises (currently not for the Enterprise cloud) and offer a 25% discount on the regular prices as a part of this. Once you purchased the first Enterprise on-premises license for a client, you receive an Enterprise on-premises license for 25 users free of charge for your internal use. Please refer to the link above for more information and the conditions regarding this offer.
Please [let us know](mailto:sales@openproject.com) if you have a particular customer request that we can send you a quote for.