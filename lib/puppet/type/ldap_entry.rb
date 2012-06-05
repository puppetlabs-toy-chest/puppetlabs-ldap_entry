module Puppet
  newtype(:ldap_entry) do
    @doc = "Some documentation on how ldap_entry works."

    ensurable

    newparam(:name) do
      desc "Name attribute for ldap_entry."

      isnamevar
    end

    newparam(:admin_dn) do
      desc "Administrative user dn for accessing LDAP."
    end

    newparam(:admin_pw) do
      desc "Password for the admin using."
    end

    newparam(:admin_default_pw) do
      desc "The password that is set for the admin user when the LDAP
        server is initially set up.  We want this so that we can change
        the admin user's password using puppet."

      defaultto 'secret'
    end

    newparam(:server) do
      desc "Resolvable name for the LDAP server that we are going to manage.
        This is most likely localthost but since we seldom put localhost into
        a SSL certificate as a valid name this should be a FQDN."

    end

    newparam(:port) do
      desc "The port that we are going to be using to communicate with the LDAP
        server."

        defaultto 10636
    end

    newproperty(:objectclass) do
      desc "The list of objectclasses that are to be present in the entry."

      isrequired

      # Have to redefine should= here so we can sort the array that is given to
      # us by the manifest.
      def should=(value)
        super
        @should.sort!
      end
    end

    newproperty(:attributes) do
      desc "A set of attributes that needs to be synced for ldap_entry."

      isrequired
    end
  end
end
