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

      isrequired
    end

    newparam(:port) do
      desc "The port that we are going to be using to communicate with the LDAP
        server."

        defaultto 10636
    end

    newparam(:entry_management) do
      desc "Designates how we treat the syncronization of the enty we are currently
        managing.  Used by the provider to determine if the entry is truth or
        additive, inclusive or minimal."

      newvalues(:inclusive, :minimal)

      defaultto :minimal
    end

    newproperty(:objectclass, :array_matching => :all) do
      desc "The list of objectclasses that are to be present in the entry."

      # Have to redefine should= here so we can sort the array that is given to
      # us by the manifest.
      def should=(value)
        super
        @should.sort!
      end

      # Overriding insync? so we can instead of comparing the entire array of is and
      # should, we really just want to know if all the should values are present
      # in the is.  This is primarily to support minimal attribute management mode.
      def insync?(is)
        case @resource[:entry_management]
        when :inclusive
          super
        when :minimal
          synced = true
          provider.objectclass_to_update = Array.new
          @should[0].each do |v|
            unless is.include?(v)
              synced = false
              provider.objectclass_to_update << v
            end
          end
          synced
        end
      end

      isrequired
    end

    newproperty(:attributes) do
      desc "A set of attributes that needs to be synced for ldap_entry."

      # Historically people have a tendency to use camel case attribute names
      # in LDAP entries but LDAP is in fact case-insensitive and some libraries
      # return all lowercase attributes names.  To make is and should comparisons
      # work we need to make sure all hash keys are downcased.
      munge do |value|
        new_hash = Hash.new
        value.each do |k, v|
          new_hash[k.downcase] = value[k].to_a
        end
        new_hash
      end

      # Overriding insync? so we can instead of comparing the entire hash of is and
      # should, we really just want to know if all the should values are present
      # in the is.  This is primarily to support minimal attribute management mode.
      def insync?(is)
        synced = true
        provider.attributes_to_update = Hash.new
        @should[0].each do |k, v|
          unless is[k] == v
            synced = false
            provider.to_update[k] = v
          end
        end
        synced
      end

      isrequired
    end
  end
end
