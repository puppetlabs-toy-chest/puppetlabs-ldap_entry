Puppet::Type.type(:ldap_entry).provide(:net_ldap) do
  desc 'Provides ruby for the type ldap_entry'

  require 'net/ldap'

  attr_accessor :attributes_to_update
  attr_accessor :objectclass_to_update

  def connect
    unless @connection
      Puppet.debug("Creating new LDAP connection to #{@resource[:server]}")
      @connection = Net::LDAP.new(
          :port        => @resource[:port],
          :host        => @resource[:server],
          :encryption  => :simple_tls,
          :auth        => {
            :method   => :simple,
            :username => @resource[:admin_dn],
            :password => @resource[:admin_pw],
          }
        )
      if @connection.bind
        Puppet.debug("Successfully authenticated LDAP connection to #{@resource[:server]} with admin_pw value")
      else
        Puppet.debug("Failed to authenticate LDAP connection to #{@resource[:server]} with admin_pw value, trying admin_default_pw")
        @connection = Net::LDAP.new(
          :port        => @resource[:port],
          :host        => @resource[:server],
          :encryption  => :simple_tls,
          :auth        => {
            :method   => :simple,
            :username => @resource[:admin_dn],
            :password => @resource[:admin_default_pw],
          }
        )
        if @connection.bind
          Puppet.debug("Successfully authenticated LDAP connection to #{@resource[:server]} with admin_default_pw value")
        else
          raise Puppet::Error, "Unable to create connection to #{resource[:server]}"
        end
      end
    end
    nil
  end

  def exists?
    connect unless @connection
    @connection.search(:base => @resource[:name], :return_result => false)
  end

  def objectclass
    connect unless @connection
    @connection.search(:base => @resource[:name]).first.objectclass.sort
  end

  def objectclass=(should)
    connect unless @connection
    case @resource[:entry_management]
    when :inclusive
      Puppet.debug("Replacing all objectclasses for the #{@resource[:name]} entry")
      @connection.modify(:dn => @resource[:name], :operations => [[ :replace, :objectclass, should ]])
    when :minimal
      Puppet.debug("Adding the objectclasses #{@resource[:objectclass]} to entry #{@resource[:name]}")
      @connection.modify(:dn => @resource[:name], :operations => [[ :replace, :objectclass, (objectclass_to_update + objectclass)]])
    end
  end

  def attributes
    connect unless @connection
    data = Hash.new
    @connection.search(:base => @resource[:name]) do |entry|
      data = Net::LDAP::Dataset.from_entry(entry)[entry.dn]
      data.delete(:objectclass)
    end
    desymbolize(data)
  end

  # I really don't like this solution for syncing attributes but it is the
  # simplest.  Will think about identifying which individual attributes are
  # out of sync and doing a modify.
  def attributes=(should)
    connect unless @connection
    case @resource[:entry_management]
    when :inclusive
      Puppet.debug("Replacing entire #{@resource[:name]} entry")
      data = should
      data['objectclass'] = @resource[:objectclass]
      @connection.delete(:dn => @resource[:name])
      @connection.add(:dn => @resource[:name], :attributes => data)
    when :minimal
      attributes_to_update.each do |k, v|
        Puppet.debug("Updating #{k} with #{v} for entry #{@resource[:name]}")
        @connection.modify(:dn => @resource[:name], :operations => [[ :replace, k.to_sym, v ]])
      end
    end
  end

  def create
    connect unless @connection
    data = @resource[:attributes]
    data['objectclass'] = @resource[:objectclass]
    @connection.add(:dn => @resource[:name], :attributes => data)
  end

  def destroy
    connect unless @connection
    @connection.delete(:dn => @resource[:name])
  end

  # The hashes that puppet support can't have symbols for keys.  This causes us
  # the need to take hashes we get for net/ldap and de-symbol them so
  # comparison works.
  def desymbolize(hash)
    new_hash = Hash.new
    hash.each do |k, v|
      new_hash[k.to_s] = v
    end
    new_hash
  end
end
