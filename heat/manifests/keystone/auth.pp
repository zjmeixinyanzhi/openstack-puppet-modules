# == Class: heat::keystone::auth
#
# Configures heat user, service and endpoint in Keystone.
#
# === Parameters
# [*password*]
#   (Required) Password for heat user.
#
# [*email*]
#   (Optional) Email for heat user.
#   Defaults to 'heat@localhost'.
#
# [*auth_name*]
#   (Optional) Username for heat service.
#   Defaults to 'heat'.
#
# [*configure_endpoint*]
#   (Optional) Should heat endpoint be configured?
#   Defaults to 'true'.
#
# [*configure_user*]
#   (Optional) Whether to create the service user.
#   Defaults to 'true'.
#
# [*configure_user_role*]
#   (Optional) Whether to configure the admin role for the service user.
#   Defaults to 'true'.
#
# [*service_name*]
#   (Optional) Name of the service.
#   Defaults to the value of auth_name.
#
# [*service_type*]
#   (Optional) Type of service.
#   Defaults to 'orchestration'.
#
# [*public_address*]
#   (Optional) Public address for endpoint.
#   Defaults to '127.0.0.1'.
#
# [*admin_address*]
#   (Optional) Admin address for endpoint.
#   Defaults to '127.0.0.1'.
#
# [*internal_address*]
#   (Optional) Internal address for endpoint.
#   Defaults to '127.0.0.1'.
#
# [*version*]
#   (Optional) Version of API to use.
#   Defaults to 'v1'
#
# [*port*]
#   (Optional) Port for endpoint.
#   Defaults to '8004'.
#
# [*region*]
#   (Optional) Region for endpoint.
#   Defaults to 'RegionOne'.
#
# [*tenant*]
#   (Optional) Tenant for heat user.
#   Defaults to 'services'.
#
# [*protocol*]
#   (Optional) Protocol for public endpoint.
#   Defaults to 'http'.
#
# [*public_protocol*]
#   (Optional) Protocol for public endpoint.
#   Defaults to 'http'.
#
# [*admin_protocol*]
#   (Optional) Protocol for admin endpoint
#   Defaults to 'http'.
#
# [*internal_protocol*]
#   (Optional) Protocol for internal endpoint
#   Defaults to 'http'
#
class heat::keystone::auth (
  $password             = false,
  $email                = 'heat@localhost',
  $auth_name            = 'heat',
  $service_name         = undef,
  $service_type         = 'orchestration',
  $public_address       = '127.0.0.1',
  $admin_address        = '127.0.0.1',
  $internal_address     = '127.0.0.1',
  $port                 = '8004',
  $version              = 'v1',
  $region               = 'RegionOne',
  $tenant               = 'services',
  $public_protocol      = 'http',
  $admin_protocol       = 'http',
  $internal_protocol    = 'http',
  $configure_endpoint   = true,
  $configure_user       = true,
  $configure_user_role  = true,
) {

  validate_string($password)

  if $service_name == undef {
    $real_service_name = $auth_name
  } else {
    $real_service_name = $service_name
  }

  keystone::resource::service_identity { $auth_name:
    configure_user      => $configure_user,
    configure_user_role => $configure_user_role,
    configure_endpoint  => $configure_endpoint,
    service_type        => $service_type,
    service_description => 'Openstack Orchestration Service',
    service_name        => $real_service_name,
    region              => $region,
    password            => $password,
    email               => $email,
    tenant              => $tenant,
    public_url          => "${public_protocol}://${public_address}:${port}/${version}/%(tenant_id)s",
    admin_url           => "${admin_protocol}://${admin_address}:${port}/${version}/%(tenant_id)s",
    internal_url        => "${internal_protocol}://${internal_address}:${port}/${version}/%(tenant_id)s",
  }

  if $configure_user_role {
    Keystone_user_role["${auth_name}@${tenant}"] ~>
      Service <| name == 'heat-api' |>
  }

  keystone_role { 'heat_stack_user':
        ensure => present,
  }

}
