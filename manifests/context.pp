define ldap_entry::context(
  $organization,
  $domain_name,
  $ensure = present,
) {

  ldap_entry { $domain_name:
    ensure           => $ensure,
    objectclass      => [ 'dcObject', 'organization', 'top' ],
    attributes       => { 'dc' => $name, 'o' => $organization },
    context          => true,
    entry_management => inclusive,
  }
}
