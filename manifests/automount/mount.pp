define ldap_entry::automount::mount(
  $base,
  $auto_info,
  $ensure = present,
) {

  ldap_entry { "cn=${name},${base}":
    ensure      => $ensure,
    objectclass => [ 'automount', 'top' ],
    attributes  => { 'cn' => $name },
  }
}
