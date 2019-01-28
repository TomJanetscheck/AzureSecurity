#!/bin/sh

# Create Azure AD service principal in subscription <yourSubscriptionID>
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/<yourSubscriptionID>"