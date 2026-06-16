---
sidebar_navigation:
  title: LDAP group synchronization
  priority: 002
description: Synchronize LDAP groups.
keywords: synchronize ldap groups
---

# Synchronize LDAP and OpenProject groups (Enterprise add-on)

This feature is available for the Enterprise edition only. For more information and differences to Community edition, [see the Enterprise edition overview](https://www.openproject.org/enterprise-edition/).

In OpenProject Enterprise edition, you can provision and periodically synchronize groups and their members from your existing LDAP or Active Directory. This guide assumes that you:

- have set up your LDAP authentication source (See the “[Manage LDAP authentication](../../ldap-connections/)” guide)
- have LDAP group entries whose members can be discovered either via the `memberOf` attribute on user entries (reverse lookup, default) or via a member list attribute on the group entry such as `uniqueMember` or `member` (forward lookup, configurable).

> [!NOTE]
> This feature is available for both Enterprise cloud and Enterprise on-premises. When using Enterprise cloud, your LDAP server must be reachable from the OpenProject cloud infrastructure, which typically means exposing it to the internet, which is not recommended. This is a network and security consideration for your organization to evaluate. Consider using [SAML](../../saml/) or [SCIM provisioning](../../scim/) as a more secure alternative.

For the sake of simplicity, we assume that in this guide, your LDAP structure looks like the following:

![ldap-groups](ldap-groups-1-900x363@2x.png)

You have two groups *cn=groupA,ou=groups,ou=example,ou=com and cn=groupB,ou=groups,ou=example,ou=com* with two and one users, respectively*.* Your base DN is *ou=people,ou=example,ou=com.*

You can use this integration in the following two ways:

1. Synchronizing a single LDAP group
2. Specifying an LDAP filter that targets a set of groups and their members

In order to get to the LDAP group sync administration pane, expand the LDAP authentication menu item in your administration.

## Synchronized group: Synchronizing a single LDAP group

Synchronizing a single LDAP group allows you to connect an existing group in OpenProject with one from LDAP.

LDAP group synchronization extends the memberships defined by administrators in an existing OpenProject group. Important things to note are:

- You need to have created at least one manual group in the OpenProject administration before you continue.
- Group synchronization for this group is enabled by an administrator creating a *synchronized LDAP group* that ties the OpenProject group to an LDAP entry.
- Only synchronized memberships will be removed from the OpenProject group. If you want to add a user outside your LDAP authentication to an OpenProject group, you can do so without the membership being affected from the group synchronization.

### Single synchronized groups

To create a new synchronized group, use the button on the top right of the page. There, you will select your LDAP authentication source that contains the group, as well as the existing OpenProject group that members should be synchronized to. The following options can be set:

- **LDAP connection:** Select the LDAP connection you want this synchronized group to use. Users created by group synchronization will be tied to that LDAP and may bind against it for authentication.
- **DN:** Enter the full distinguished name (DN) of the group you want to synchronize. For example: `cn=team1,ou=groups,dc=example,dc=com`.
- **Sync users:** Check this option if you want members of this group to be automatically created in OpenProject. When unchecked, only members of the group that also are existing users in OpenProject can be synchronized.
- **Group:** Select an OpenProject group you want the members of the LDAP group to synchronize to.

Click on *Create* to finish the creation of the synchronized group. The LDAP memberships of each user will be synchronized hourly through a background job.

To trigger a full synchronization manually (group discovery **and** member sync), run the following rake task in a [console](../../../../installation-and-operations/operation/control/):

```shell
bundle exec rake ldap_groups:synchronize
```

This method of creating synchronized groups is well-suited for a small number of groups, or a carefully selected set of groups that you need to synchronize. It is very flexible by allowing individual groups to synchronize users into OpenProject.

If you need to synchronize a large number of groups that follow a common pattern, consider using the following filter functionality.


## Automatic groups using synchronized filters

Instead of manually synchronizing groups from a given group DN in your LDAP, you can also create filter objects that automatically discover matching groups in your LDAP and synchronize their members.

When the synchronization task is executed, the filter is being queried against the LDAP and resulting group objects will be created as synchronized groups *and* as OpenProject groups.

![LDAP synchronized filter form in OpenProject administration](openproject_system_guide_add_ldap_filter.png)

### Create a synchronized filter

To create a new synchronized filter, use the button on the top right of the index page. There, you will select your LDAP authentication source that should be queried. The following properties can be set:

- **Name:** Name of the LDAP filter, only for organizational purposes
- **Group name attribute:** The attribute used for naming the associated OpenProject groups.
- **Sync users:** Check this option if you want members of all synchronized groups this filter creates to be automatically created in OpenProject. When unchecked, only members of any group that also are existing users in OpenProject can be synchronized.
- **LDAP connection:** Select the LDAP connection you want this synchronized filter to use. Users created by group synchronization will be tied to that LDAP and may bind against it for authentication.
- **Search base DN:** (optional) Enter the base DN of the LDAP subtree you want to perform the search in. If you leave this unset, the base DN of the LDAP connection will be used instead. The DN specified here must contain the base DN of the LDAP connection to be valid.
- **LDAP filter:** The LDAP filter string to be used for identifying LDAP group entries to be synchronized with OpenProject.
- **Group member attribute:** (optional) The attribute on group entries that lists member DNs, used for forward lookup. Leave empty (default) to use reverse lookup via the `memberOf` attribute on user entries. Set this to `uniqueMember` for `groupOfUniqueNames` schemas, or `member` for `groupOfNames` schemas. Use forward lookup when your LDAP server does not maintain `memberOf` on user entries.

Click on *Create* to finish the creation of the synchronized filter. This filter is being executed hourly as part of the background job before the actual group synchronization runs.

Once the filter is created, the **Discover LDAP groups** button on the filter detail page runs the discovery immediately: it queries LDAP using the filter and creates the corresponding synchronized groups and OpenProject groups. It does **not** synchronize group members — member synchronization is handled by the hourly background job.

To trigger a full synchronization (group discovery **and** member sync) manually, run the following rake task in a [console](../../../../installation-and-operations/operation/control/):

```shell
bundle exec rake ldap_groups:synchronize
```

> [!NOTE]
> Forward lookup via the **Group member attribute** is only available for groups created through a synchronized filter. Manually-created synchronized groups always use reverse lookup (`memberOf`).

> [!NOTE]
> If you manually create a synchronized group that is also found by a filter, its properties (such as the *Sync users* setting) are overridden by the filter settings.

## FAQ

### Are nested / recursive LDAP groups supported?

No, at this point in time, nested LDAP groups (i.e., group DNs being memberOf of another group entry) are not supported in OpenProject.
However, there is a feature ticket for this in the [wish list](https://community.openproject.org/projects/openproject/work_packages/34049).

If you'd like to voice your interest in this feature, please comment it with your use-case to provide visibility.

## Troubleshooting

### LDAP groups are not being synchronized

Please double check the DN of the groups and the LDAP connection. The base DN of the LDAP connection and the DN must share a common hierarchy. Otherwise, the group DN will not be found by the connection, as the base DN is used for all subsequent queries for the lifetime of the connection.

### Users are not being synchronized

For users to be automatically synchronized, the following conditions need to be met:

1. The connection, or the LDAP group need to have "Sync users" checked. This setting overrides the LDAP connection's "Sync users" attribute for fine-grained control over which groups will have users synchronized.
2. OpenProject needs to be able to resolve group members. By default it uses **reverse lookup**: it searches for users with the filter `(memberOf=<DN of the group>)`, which requires `memberOf` to be present on user entries (Active Directory, OpenLDAP with memberof overlay). If your LDAP server does not support `memberOf`, configure **forward lookup** by setting the **Group member attribute** on the synchronized filter (e.g. `uniqueMember` or `member`). You can use `ldapsearch` to verify either approach works as expected.
3. The users defined in the groups need to have all required attributes present and non-empty to be created: *login, email, first and last name*. If any of these attributes are missing or empty, the user cannot be saved to the database.
4. The **Login** attribute configured on the LDAP connection must match an attribute that is actually present on your LDAP user entries. If the attribute name is wrong or absent, users will be found in the group but not matched or created in OpenProject. Verify the attribute name against your LDAP schema and update the LDAP connection configuration if needed.
5. If your enterprise license exceeds the user limit, new users cannot be synchronized through LDAP. On-premises users will find a corresponding entry in the application logs.
