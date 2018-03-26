require 'docker'

module ContainerNotify
  module Util
    CGROUPS = '/proc/self/cgroup'.freeze

    module_function

    def current_container_id
      container = nil

      File.foreach(CGROUPS) do |line|
        container = line[/.*docker.([A-Za-z0-9]+).*/, 1]

        break unless container.nil?
      end

      container
    end

    def current_container
      Docker::Container.get(current_container_id)
    end
  end
end
