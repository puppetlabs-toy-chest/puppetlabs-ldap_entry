define ldap_entry::automount::map(
  $base,
  $ensure = present,
) {

  ldap_entry { "ou=${name},${base}":
    ensure      => $present,
    objectclass => [ 'automountMap', 'top' ],
    attributes  => { 'ou' => $name },
  }
}
