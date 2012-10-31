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

      def colliding_configuration(configuration)
        all.find do |security_group|
          security_group.name == configuration[:name]
        end
      end

      def build_for_configuration(configuration)
        colliding_configuration = colliding_configuration(configuration)
        if colliding_configuration
          new_group = colliding_configuration.merge_attributes(configuration)
        else
          new_group = all.new(transform_configuration(configuration))
        end
        new_group.save
      end

      def build_for_configurations(configurations)
        configurations.each do |configuration|
          build_for_configuration(configuration)
        end
      end

      def servers_for_groups
        all.reduce({}) do |memo, current|
          memo[current.name] = Boucher::Servers.with_group(current.name)
          memo
        end
      end

      def associate_servers(server_mapping)
        servers = Boucher::Servers.all
        servers.each do |s|
          groups = server_mapping[s.name]
          if groups
            s.groups = groups
            s.save
          end
        end
      end
    end
  end
end