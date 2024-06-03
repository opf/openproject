---
sidebar_navigation:
  title: Enterprise on-premises FAQ
  priority: 001
description: Frequently asked questions regarding Enterprise on-premises
keywords: Enterprise on-premises FAQ, enterprise edition, self-hosted
---


# Frequently asked questions (FAQ) for Enterprise on-premises

## How can I test the OpenProject Enterprise on-premises?

You can test the on-premises version 14 days for free by generating a free trial token on our [pricing site](https://www.openproject.org/pricing/). If you already have a Community edition installed, you can simply upgrade the existing installation with this token. It will automatically switch back to the Community version afterwards without any need for cancellation.

If you do not yet have an own Community installation, the easiest way to test OpenProject is to create a 14 days free trial on our [Enterprise cloud](https://start.openproject.com/). If you want to proceed, you can then switch to a self-hosted version by choosing one of our [paid plans](https://www.openproject.org/pricing/).

## How can I upgrade from the Community to the Enterprise on-premises edition?

The Enterprise on-premises edition is an upgrade of the self-hosted Community edition. When you are already using the Community edition, you can purchase an Enterprise on-premises edition license to upgrade to the Enterprise on-premises edition. To do this, follow these steps:

1. Navigate to [www.openproject.org/enterprise-edition/](https://www.openproject.org/enterprise-edition/).
2. Click on the "Book now" button.
3. Follow the steps to purchase the Enterprise on-premises edition license. You will then receive an Enterprise on-premises edition license key by email which you can use to upgrade your Community edition to the Enterprise on-premises edition.

If you prefer to test the Enterprise on-premises edition before purchasing, you can request a 14 day trial license from within your system (*Administration -> Enterprise edition*). Simply click on the green **Start free trial** button to receive a 14 day trial license. If you want to continue, you can navigate to our [pricing page](https://www.openproject.org/pricing/) and choose a plan. Otherwise, you will automatically be downgraded to the Community edition. There is no need to cancel the trial.

Find more information [here](https://www.openproject.org/blog/enterprise-edition-upgrade-test-free/).

## How can I book additional users?

Please use the link "Manage subscription" in the email you received confirming your subscription or contact sales@openproject.com.

## Is it possible to only upgrade *some* users to the Enterprise edition?

This is not possible, as the Enterprise add-ons affect the whole OpenProject instance and not the individual users.

## I didn't receive my license key / Enterprise token

The Enterprise token is sent to the email address used to create the subscription. If you can't find it in the spam folder and if you already paid for the subscription please contact support.

## Can I use my own domain name?

Yes, for Enterprise on-premises and for Community edition you will have to choose your own domain name during [initial configuration](../../../installation-and-operations/installation/packaged/#initial-configuration) after installing OpenProject.

## Are also the Enterprise add-ons open source?

Yes, all features, also the Enterprise add-ons, are developed under the GPL v3.

## Why do you not offer all features for free?

The developers of OpenProject love this project. And they love open source development. They work hard to build powerful new features and fix bugs with every release. However, they also need to pay rent, taxes, health insurance and so on. To be able to work on OpenProject and keep the speed, they need funding.

## How can I change my payment details (e.g. new credit card)?

Please use the link "Manage subscription" in the first email you received from our system. Alternatively, please contact support via email.

## How can I downgrade from Enterprise on-premises to Community edition?

To downgrade to the Community edition you will simply need to cancel the paid Enterprise plan. As soon as the subscription terminates, you will automatically switch back to the Community version. Please note that you will not be able to use the Enterprise add-ons anymore and you will not be eligible for support. As soon as your subscription or your trial ends you will automatically be downgraded to the Community edition.

## Can I migrate from the hosted Enterprise cloud edition to a self-hosted Community or Enterprise on-premises edition?

Yes. If you want to switch from a hosted version of OpenProject (Enterprise cloud edition) to a self-hosted version (Community edition or Enterprise on-premises) we can provide you a full dump of your data. Since this requires manual effort for us, we may charge for this service . Please [contact us](https://www.openproject.org/contact/) to get a quotation.

## I can't login via SSO to update my Enterprise on-premises token. What do I do?

Until this issue is fixed you can set the token manually via the console. Copy the new token and then do the following.

```shell
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
