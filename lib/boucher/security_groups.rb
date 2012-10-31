require 'boucher/compute'
require 'boucher/servers'

module Boucher

  module SecurityGroups
    SECURITY_GROUP_TABLE_FORMAT = "%-12s  %-12s  %-10s  %-50s\n"

    module Printing
      def self.print_table(security_groups, servers_for_groups)
        printf SECURITY_GROUP_TABLE_FORMAT, "ID", "Name", "Environment", "Servers"
        puts
        security_groups.each do |security_group|
          printf SECURITY_GROUP_TABLE_FORMAT,
            security_group.group_id,
            security_group.name,
            "????",
            servers_for_groups[security_group.name].map(&:id)
        end
      end
    end

    class << self
      def all
        Boucher.compute.security_groups
      end

      def transform_configuration(configuration)
        new_configuration = {}
        new_configuration[:name] = configuration[:name]
        new_configuration[:description] = configuration[:description]
        new_configuration[:ip_permissions] = configuration[:ip_permissions].map do |permission|
          new_permission = {}
          new_permission[:groups] = permission[:groups]
          new_permission[:from_port] = permission[:from_port]
          new_permission[:to_port] = permission[:to_port]
          new_permission[:ipProtocol] = permission[:protocol]
          new_permission[:ipRanges] = permission[:incomingIPs].map do |ip|
            {cidrIp: ip}
          end
          new_permission
        end
        new_configuration
      end

      def build_for_configuration(configuration)
        all.new(transform_configuration(configuration))
      end

      def build_for_configurations(configurations)
        configurations.each do |configuration|
          all.new(transform_configuration(configuration))
        end
        all.save
      end

      def servers_for_groups
        all.reduce({}) do |memo, current|
          memo[current.name] = Boucher::Servers.with_group(current.name)
          memo
        end
      end
    end
  end
end
