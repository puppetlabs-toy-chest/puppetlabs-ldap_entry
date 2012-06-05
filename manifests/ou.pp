define ldap_entry::ou(
  $base,
  $ensure = present,
) {

  ldap_entry { "ou=${name},${base}":
    ensure      => $ensure,
    objectclass => [ 'organizationalUnit', 'top' ],
    attributes  => { 'ou' => $name },
  }
}
