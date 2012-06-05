Puppet::Type.type(:ldap_entry).provide(:ruby) do
  desc 'Provides ruby for the type ldap_entry'

  require 'net/ldap'

  def initialize
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
  end

  # Checks the property_hash for the existance of the resource in question.
  def exists?
    @connection.search(:base => @resource[:name], :return_result => false)
  end

  def objectclass
    @connection.search(:base => @resource[:name]).first.objectclass.sort
  end

  def objectclass=(should)
    @connection.modify(:dn => @resource[:name], :operations => [[ :replace, :objectclass, should ]])
  end

  def attributes
    data = Hash.new
    @connection.search(:base => @resource[:name]).first do |entry|
      data = Net::LDAP::Dataset.from_entry(entry)[entry.dn]
      data.delete(:objectclass)
    end
    data
  end

  # I really don't like this solution for syncing attributes but it is the
  # simplest.  Will think about identifing which individual attributes are
  # out of sync and doing a modify.
  def attributes=(should)
    data = should
    data[:objectclass] = @resource[:objectclass]
    @connection.delete(:dn => @resource[:name])
    @connection.add(:dn => @resource[:name], :attributes => data)
  end

  def create
    data = @resource[:attributes]
    data[:objectclass] = @resource[:objectclass]
    @connection.add(:dn => @resource[:name], :attributes => data)
  end

  def destroy
    @connection.delete(:dn => @resource[:name])
  end
end
