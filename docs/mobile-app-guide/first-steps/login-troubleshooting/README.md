---
sidebar_navigation:
  title: Login Troubleshooting
  priority: 700
description: Resolve the most common issues logging in to the OpenProject Mobile app.
keywords: Mobile App Login Troubleshooting, log in error, mobile app troubleshooting, mobile app error
---

# Login Troubleshooting

If you’re having trouble logging into the **OpenProject Mobile App**, the following sections will help you identify and resolve the most common issues.

## Invalid or Inaccessible Instance URL

**Symptom:**  
You see a browser error such as _“The site can't be reached. The server address could not be found”_.

**Cause:**  
The URL you entered may be incorrect, inaccessible, or not using HTTPS.

**Possible Solution:**

- Double-check the URL format (e.g., `https://yourcompany.openproject.com`).
- Ensure your instance is publicly accessible and uses **HTTPS** (HTTP is not supported).
- Try opening the same URL in your mobile browser to confirm connectivity.

## OAuth Application Not Enabled

**Symptom:**  
Login fails with a browser error such as _“An authorization error has occurred. The client is not authorized to perform this request using this method.”, or you are redirected back to the login screen without authentication.

**Cause:**  
The mobile app uses OAuth 2.0 for secure authentication. If the built-in OAuth applications are not enabled in your instance, the app cannot log you in.

**Possible Solution:**

1. Go to your OpenProject administration area at:  
    `{BASE_URL}/admin/oauth/applications`
2. Make sure that **Built-in OAuth applications** are enabled.
3. If you don’t have admin rights, contact your OpenProject administrator.

## Instance Not on Minimum Supported Version

**Symptom:**  
You know that your instance is running not on the minimum supported version, OpenProject 17.0.0, and the login fails with a browser error such as _“An authorization error has occurred. The client is not authorized to perform this request using this method.”_.

**Cause:**  
The OpenProject Mobile App requires your instance to be on **OpenProject version 17.0.0 or higher**.  
If your instance is running an older version, OAuth authentication may be disabled by default.

**Possible Solution:**

- Ask your OpenProject administrator to check the current version of your instance.
- Update to newer version of OpenProject.
  - If updating is not am option, the administrator can **temporarily enable OAuth authentication** by removing the feature flag under: `{BASE_URL}/admin/settings/experimental`
  - Once this flag is removed, the built-in OAuth applications will be available in `{BASE_URL}/admin/oauth/applications`, once enabled the users can log in via the mobile app.

> [!NOTE]
> Upgrading to the latest OpenProject version is recommended for the best compatibility and security. 

## Invalid SSL Certificate

**Symptom:**  
You receive a browser error message such as _“Secure connection failed. Untrusted certificate”_.

**Cause:**  
Your OpenProject instance must use a **valid, signed SSL certificate** (HTTPS). Self-signed certificates or expired certificates are not supported.

**Possible Solution:**

- Verify that your SSL certificate is valid and trusted by your device.
- If you’re using a self-signed certificate, replace it with one from a trusted certificate authority (CA).
    
## Wrong Credentials

**Symptom:**  
You see _“Invalid username or password”_ when logging in.

**Cause:**  
Your login credentials are incorrect or have been changed.

**Possible Solution:**

- Make sure you’re using your **OpenProject account credentials**, not your email alias (unless configured as your username).
- Try logging in via the web version of OpenProject to confirm your credentials.
- Reset your password if necessary.

## On-Premises API Access Disabled

**Symptom:**  
Login attempts fail with no clear error message.

**Cause:**  
Your on-premises OpenProject instance may have **API access disabled**, preventing the mobile app from connecting.

**Possible Solution:**

- Log in as an administrator and navigate to:  
    `Administration → System settings → API`
- Ensure that **API access** is enabled.
- Save changes and try logging in again.
    
## Instance Using HTTP Instead of HTTPS

**Symptom:**  
You receive a browser error message such as _“Secure connection failed. Untrusted certificate”_.

**Cause:**  
The mobile app only supports secure connections via **HTTPS**.

**Possible Solution:**

- Configure your instance to use HTTPS with a valid certificate.
- Redirect HTTP traffic to HTTPS using your web server configuration.

## Firewall or Network Restrictions

**Symptom:**  
Login attempts time out or fail when using certain networks with an error such as “Login time out. Check your network”.

**Cause:**  
Corporate or restricted networks may block outbound requests to your OpenProject instance or authentication endpoints.

**Possible Solution:**

- Check the network connection of your device. Internet access is required for the app to work.
- Try connecting from a different network (e.g., mobile data).
- Ask your IT team to whitelist your OpenProject domain.
