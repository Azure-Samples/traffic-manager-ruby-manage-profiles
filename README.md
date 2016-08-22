---
services: traffic-manager
platforms: ruby
author: vishrutshah
---

# Manage traffic manager profiles using Ruby

This sample demonstrates how to manage Azure traffic manager profiles using the Ruby SDK.

**On this page**

- [Run this sample](#run)
- [What is example.rb doing?](#example)
    - [Create a profile](#create)
    - [List profiles](#list)
    - [Delete a profile](#delete)

<a id="run"></a>
## Run this sample

1. If you don't already have it, [install Ruby and the Ruby DevKit](https://www.ruby-lang.org/en/documentation/installation/).

1. If you don't have bundler, install it.

    ```
    gem install bundler
    ```

1. Clone the repository.

    ```
    git clone https://github.com/Azure-Samples/traffic-manager-ruby-manage-profiles.git
    ```

1. Install the dependencies using bundle.

    ```
    cd traffic-manager-ruby-manage-profiles
    bundle install
    ```

1. Create an Azure service principal either through
    [Azure CLI](https://azure.microsoft.com/documentation/articles/resource-group-authenticate-service-principal-cli/),
    [PowerShell](https://azure.microsoft.com/documentation/articles/resource-group-authenticate-service-principal/)
    or [the portal](https://azure.microsoft.com/documentation/articles/resource-group-create-service-principal-portal/).

1. Set the following environment variables using the information from the service principle that you created.

    ```
    export AZURE_TENANT_ID={your tenant id}
    export AZURE_CLIENT_ID={your client id}
    export AZURE_CLIENT_SECRET={your client secret}
    export AZURE_SUBSCRIPTION_ID={your subscription id}
    ```

    > [AZURE.NOTE] On Windows, use `set` instead of `export`.

1. Run the sample.

    ```
    bundle exec ruby example.rb
    ```

<a id="example"></a>
## What is example.rb doing?

This sample starts by setting up ResourceManagementClient and TrafficeManager objects using your subscription and credentials.

```ruby
#
# Create the Resource Manager Client with an Application (service principal) token provider
#
subscription_id = ENV['AZURE_SUBSCRIPTION_ID'] || '11111111-1111-1111-1111-111111111111' # your Azure Subscription Id
provider = MsRestAzure::ApplicationTokenProvider.new(
    ENV['AZURE_TENANT_ID'],
    ENV['AZURE_CLIENT_ID'],
    ENV['AZURE_CLIENT_SECRET'])
credentials = MsRest::TokenCredentials.new(provider)

# resource client
resource_client = Azure::ARM::Resources::ResourceManagementClient.new(credentials)
resource_client.subscription_id = subscription_id

# traffic manager client
traffic_manager_client = Azure::ARM::TrafficManager::TrafficManagerManagementClient.new(credentials)
traffic_manager_client.subscription_id = subscription_id
```

It registers the subscription for the "Microsoft.Media" namespace
and creates a resource group.

```ruby
#
# Register subscription for 'Microsoft.Media' namespace
#
provider = resource_client.providers.register('Microsoft.Media')

#
# Create a resource group
#
resource_group_params = Azure::ARM::Resources::Models::ResourceGroup.new.tap do |rg|
    rg.location = REGION
end

resource_group = resource_client.resource_groups.create_or_update(RESOURCE_GROUP_NAME, resource_group_params)
```

There are a couple of supporting functions (`print_item` and `print_properties`) that print a resource group and it's properties.
With that set up, the sample lists all resource groups for your subscription, it performs these operations.

<a id="create"></a>
### Create a profile

```ruby
param = Azure::ARM::TrafficManager::Models::Profile.new
param.location = 'global'
param.traffic_routing_method = 'Performance'
param.dns_config = Azure::ARM::TrafficManager::Models::DnsConfig.new.tap do |dns_config|
    dns_config.relative_name = PROFILE_NAME
    dns_config.ttl = 30
end
param.monitor_config = Azure::ARM::TrafficManager::Models::MonitorConfig.new.tap do |monitor_config|
    monitor_config.protocol = 'HTTP'
    monitor_config.port = 80
    monitor_config.path = '/sample_monitor_page'
end

profile = traffic_manager_client.profiles.create_or_update(RESOURCE_GROUP_NAME, PROFILE_NAME, param)
```

<a id="list"></a>
### List profiles

```ruby
profile_list_result = traffic_manager_client.profiles.list_all
```

<a id="delete"></a>
### Delete a profile

```ruby
traffic_manager_client.profiles.delete(RESOURCE_GROUP_NAME, PROFILE_NAME)
```
