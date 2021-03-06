# == Class: nova::network
#
# Manages nova-network.
#
# An OpenStack deployment that includes compute and networking will use either
# nova-network or Neutron.  Neutron is newer and nova-network is the legacy
# networking support built directly into Nova.  However, nova-network is still
# fully supported, is not feature frozen, and is not yet officially deprecated.
#
# === Parameters:
#
# [*private_interface*]
#   (optional) Interface used by private network.
#   Defaults to undef
#
# [*fixed_range*]
#   (optional) Fixed private network range.
#   Defaults to '10.0.0.0/8'
#
# [*public_interface*]
#   (optional) Interface used to connect vms to public network.
#   Defaults to undef
#
# [*num_networks*]
#   (optional) Number of networks that fixed range network should be
#   split into.
#   Defaults to 1
#
# [*network_size*]
#   (optional) Number of addresses in each private subnet.
#   Defaults to 255
#
# [*floating_range*]
#   (optional) Range of floating ip addresses to create.
#   Defaults to false
#
# [*enabled*]
#   (optional) Whether the network service should be enabled.
#   Defaults to true
#
# [*network_manager*]
#   (optional) The type of network manager to use.
#   Defaults to 'nova.network.manager.FlatDHCPManager'
#
# [*config_overrides*]
#   (optional) Additional parameters to pass to the network manager class
#   Defaults to {}
#
# [*create_networks*]
#   (optional) Whether actual nova networks should be created using
#   the fixed and floating ranges provided.
#   Defaults to true
#
# [*ensure_package*]
#   (optional) The state of the nova network package
#   Defaults to 'present'
#
# [*install_service*]
#   (optional) Whether to install and enable the service
#   Defaults to true
#
# [*allowed_start*]
#   (optional) Start of allowed addresses for instances
#   Defaults to undef
#
# [*allowed_end*]
#   (optional) End of allowed addresses for instances
#   Defaults to undef
#
# [*dns1*]
#   (optional) First DNS server
#   Defaults to undef
#
# [*dns2*]
#   (optional) Second DNS server
#   Defaults to undef
#
# [*multi_host*]
#   (optional) Default value for multi_host in networks.
#   Also, if set, some rpc network calls will be sent directly to host.
#   Defaults to false.
#
# [*auto_assign_floating_ip*]
#   (optional) Autoassigning floating IP to VM
#   Defaults to false.
#
class nova::network(
  $private_interface       = undef,
  $fixed_range             = '10.0.0.0/8',
  $public_interface        = undef,
  $num_networks            = 1,
  $network_size            = 255,
  $floating_range          = false,
  $enabled                 = true,
  $network_manager         = 'nova.network.manager.FlatDHCPManager',
  $config_overrides        = {},
  $create_networks         = true,
  $ensure_package          = 'present',
  $install_service         = true,
  $allowed_start           = undef,
  $allowed_end             = undef,
  $dns1                    = undef,
  $dns2                    = undef,
  $multi_host              = false,
  $auto_assign_floating_ip = false,
) {

  include ::nova::deps
  include ::nova::params

  # forward all ipv4 traffic
  # this is required for the vms to pass through the gateways
  # public interface
  Exec {
    path => $::path
  }

  ensure_resource('sysctl::value', 'net.ipv4.ip_forward', { value => '1' })

  if $floating_range {
    nova_config {
      'DEFAULT/floating_range':          value => $floating_range;
      'DEFAULT/auto_assign_floating_ip': value => $auto_assign_floating_ip;
    }
  }

  nova_config {
    'DEFAULT/multi_host': value => $multi_host;
  }

  if has_key($config_overrides, 'vlan_start') {
    $vlan_start = $config_overrides['vlan_start']
  } else {
    $vlan_start = undef
  }

  if $install_service {
    nova::generic_service { 'network':
      enabled        => $enabled,
      package_name   => $::nova::params::network_package_name,
      service_name   => $::nova::params::network_service_name,
      ensure_package => $ensure_package,
      before         => Exec['networking-refresh']
    }

    # because nova_network provider uses nova client, so it assumes
    # that nova-network service is running already
    Service<| title == 'nova-network' |> -> Nova_network<| |>
    if $create_networks {
      if $enabled {
        nova::manage::network { 'nova-vm-net':
          network       => $fixed_range,
          num_networks  => $num_networks,
          network_size  => $network_size,
          vlan_start    => $vlan_start,
          allowed_start => $allowed_start,
          allowed_end   => $allowed_end,
          dns1          => $dns1,
          dns2          => $dns2,
        }
        if $floating_range {
          nova::manage::floating { 'nova-vm-floating':
            network => $floating_range,
          }
        }
      } else {
        warning('Can not create networks, when nova-network service is disabled.')
      }
    }
  }

  case $network_manager {

    'nova.network.manager.FlatDHCPManager': {
      # I am not proud of this
      $parameters = { fixed_range      => $fixed_range,
                      public_interface => $public_interface,
                      flat_interface   => $private_interface
      }
      $resource_parameters = merge($config_overrides, $parameters)
      $flatdhcp_resource = {'nova::network::flatdhcp' => $resource_parameters }
      create_resources('class', $flatdhcp_resource)
    }
    'nova.network.manager.FlatManager': {
      $parameters = { fixed_range      => $fixed_range,
                      public_interface => $public_interface,
                      flat_interface   => $private_interface
      }
      $resource_parameters = merge($config_overrides, $parameters)
      $flat_resource = {'nova::network::flat' => $resource_parameters }
      create_resources('class', $flat_resource)
    }
    'nova.network.manager.VlanManager': {
      $parameters = { fixed_range      => $fixed_range,
                      public_interface => $public_interface,
                      vlan_interface   => $private_interface
      }
      $resource_parameters = merge($config_overrides, $parameters)
      $vlan_resource = { 'nova::network::vlan' => $resource_parameters }
      create_resources('class', $vlan_resource)
    }
    default: {
      fail("Unsupported network manager: ${nova::network_manager} The supported network managers are nova.network.manager.FlatManager, nova.network.FlatDHCPManager and nova.network.manager.VlanManager")
    }
  }

}
