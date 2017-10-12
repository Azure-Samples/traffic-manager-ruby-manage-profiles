#!/usr/bin/env ruby

require 'dotenv'
require 'azure_mgmt_resources'
require 'azure_mgmt_traffic_manager'

TrafficManager =  Azure::TrafficManager::Profiles::V2017_09_01_Preview::Mgmt
TrafficManagerModels = TrafficManager::Models
Resources = Azure::Resources::Profiles::V2017_05_10::Mgmt
ResourcesModels = Resources::Models

Dotenv.load(File.join(__dir__, './.env'))

REGION = 'East US'
RESOURCE_GROUP_NAME = 'TrafficManagerSample'
PROFILE_NAME = 'traffic-manager-sample'

# This script expects that the following environment vars are set:
#
# AZURE_TENANT_ID: with your Azure Active Directory tenant id or domain
# AZURE_CLIENT_ID: with your Azure Active Directory Application Client ID
# AZURE_CLIENT_SECRET: with your Azure Active Directory Application Secret
# AZURE_SUBSCRIPTION_ID: with your Azure Subscription Id
#
def run_example
  #
  # Create the Resource Manager Client with an Application (service principal) token provider
  #
  subscription_id = ENV['AZURE_SUBSCRIPTION_ID'] || '11111111-1111-1111-1111-111111111111' # your Azure Subscription Id
  provider = MsRestAzure::ApplicationTokenProvider.new(
      ENV['AZURE_TENANT_ID'],
      ENV['AZURE_CLIENT_ID'],
      ENV['AZURE_CLIENT_SECRET'])
  credentials = MsRest::TokenCredentials.new(provider)

  options = {
      credentials: credentials,
      subscription_id: subscription_id
  }

  # resource profile client
  resource_client = Resources::Client.new(options)

  # traffic manager profile client
  traffic_manager_client = TrafficManager::Client.new(options)

  #
  # Register subscription for 'Microsoft.KeyVault' namespace
  #
  provider = resource_client.resources.providers.register('Microsoft.Network')
  puts "#{provider.namespace} #{provider.registration_state}"

  #
  # Create a resource group
  #
  create_resource_group(resource_client)

  #
  # Create a Traffic Manager Profile
  #
  puts 'Create a Traffic Manager Profile'
  param = TrafficManagerModels::Profile.new
  param.location = 'global'
  param.traffic_routing_method = 'Performance'
  param.dns_config = TrafficManagerModels::DnsConfig.new.tap do |dns_config|
    dns_config.relative_name = PROFILE_NAME
    dns_config.ttl = 30
  end
  param.monitor_config = TrafficManagerModels::MonitorConfig.new.tap do |monitor_config|
    monitor_config.protocol = 'HTTP'
    monitor_config.port = 80
    monitor_config.path = '/sample_monitor_page'
  end

  profile = traffic_manager_client.traffic_manager.profiles.create_or_update(RESOURCE_GROUP_NAME, PROFILE_NAME, param)
  print_profile(profile)

  #
  # list all Traffic Manager Profiles
  #
  puts 'List all Traffic Manager Profiles'
  profile_list_result = traffic_manager_client.traffic_manager.profiles.list_by_subscription
  profile_list_result.value.each do |profile|
    print_profile(profile)
  end

  #
  # delete Traffic Manager Profile
  #
  puts 'Delete Traffic Manager Profile'
  puts 'Press any key to continue'
  gets
  traffic_manager_client.traffic_manager.profiles.delete(RESOURCE_GROUP_NAME, PROFILE_NAME)

  #
  # delete resource group
  #
  puts 'Delete resource group'
  puts 'Press any key to continue'
  gets
  delete_resource_group(resource_client)
end

def create_resource_group(resource_client)
  puts 'Create a resource group'
  resource_group_params = ResourcesModels::ResourceGroup.new.tap do |rg|
    rg.location = REGION
  end

  resource_group = resource_client.resources.resource_groups.create_or_update(RESOURCE_GROUP_NAME, resource_group_params)
  print_item resource_group
end

def delete_resource_group(resource_client)
  puts 'Delete a resource group'
  resource_client.resources.resource_groups.delete(RESOURCE_GROUP_NAME)
end

def print_item(item)
  puts "\tName: #{item.name}"
  puts "\tId: #{item.id}"
  puts "\tLocation: #{item.location}"
  puts "\tTags: #{item.tags}"
  print_properties(item.properties) if item.respond_to?(:properties)
end

def print_properties(props)
  if props.respond_to? :provisioning_state
    puts "\tProperties:"
    puts "\t\tProvisioning State: #{props.provisioning_state}"
  end
end

def print_profile(profile)
  print_item(profile)
  puts "\tProfileStatus: #{profile.profile_status}"
  puts "\tTrafficRoutingMethod: #{profile.traffic_routing_method}"
  print_endpoints(profile.endpoints)
end

def print_endpoints(endpoints)
  puts "\t\tEndpoints:"
  endpoints.each do |endpoint|
    puts "\tName: #{endpoint.name}"
    puts "\tId: #{endpoint.id}"
    puts "\tType: #{endpoint.type}"
    puts "\tTargetResourceId: #{endpoint.target_resource_id}"
    puts "\tTarget: #{endpoint.target}"
    puts "\tEndpointStatus: #{endpoint.endpoint_status}"
    puts "\tWeight: #{endpoint.weight}"
    puts "\tPriority: #{endpoint.priority}"
    puts "\tEndpointLocation: #{endpoint.endpoint_location}"
  end
end

if $0 == __FILE__
  run_example
end
