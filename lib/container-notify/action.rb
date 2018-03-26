require 'docker/container'

module ContainerNotify
  class Action
    attr_reader :container_method
    alias method container_method

    def initialize(container, container_method, container_params = {})
      raise "Expected a Docker::Container, got: '#{container}'" unless container.is_a?(Docker::Container)
      raise "Expected a String or Symbol, got: '#{container_method}'" unless container_method.is_a?(String) || container_method.is_a?(Symbol) # rubocop:disable Metrics/LineLength
      raise "Expected a Hash, got: '#{container_params}'" unless container_params.is_a?(Hash)

      @container = container
      @container_method = container_method.to_sym
      @container_params = container_params
    end

    def id
      @container.id
    end

    def name
      return @container.info['Names'].first if @container.info.key?('Names')
      id
    end

    def forward
      @container.send(@container_method, @container_params)
    end
  end
end
