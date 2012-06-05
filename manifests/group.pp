define ldap_entry::group(
  $gid,
  $members = '',
  $base,
  $ensure = present,
) {

  if $members != '' {
    notify { 'attribute_members':
      message => 'The attribute members for ldap_entry::group is currently a noop, until I decide how to do deal with it or even if I want to',
      log_level => debug,
    }
  }

  # Revisit the need for managing members or not.  If yes then need to find
  # a way to generate multiple memberUid entries from an array.
  ldap_entry { "cn=${name},${base}:
    ensure      => $ensure,
    objectclass => [ 'posixGroup', 'top' ],
    attributes  => { 'cn' => $name, 'gidNumber' => $gid },
  }
}
