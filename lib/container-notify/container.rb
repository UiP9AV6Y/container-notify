require 'container-notify/action'

module ContainerNotify
  class Container
    attr_reader :filters

    VALID_SIGNALS = Signal.list.keys.freeze
    RESTART_ACTION = 'RESTART'.freeze
    DEFAULT_ACTION = VALID_SIGNALS[1]

    class << self
      def by_filters(filters, action = nil)
        new(filters, action)
      end

      def by_name(name, action = nil)
        by_filters({ name: [name] }, action)
      end

      def by_project(project, action = nil)
        by_filters({ label: ["com.docker.compose.project=#{project}"] }, action)
      end

      def by_service(service, project = nil, action = nil)
        filters = {
          label: ["com.docker.compose.service=#{service}"]
        }

        filters[:label] << "com.docker.compose.project=#{project}" unless project.nil?

        by_filters(filters, action)
      end

      def by_mount(source, action = nil)
        by_filters({ volume: [source] }, action)
      end

      def parse(data, default_action = nil, query_service = false, project = nil)
        pair = data.split(':', 2)
        ident = pair[0]

        action = pair[1] || default_action

        return by_name(ident, action) unless query_service

        by_service(ident, project, action)
      end

      def normalize_action(action)
        action.to_s.upcase.sub(/SIG/, '')
      end

      def valid_action?(action)
        VALID_SIGNALS.include?(action) || action == RESTART_ACTION
      end

      def action_symbols
        syms = VALID_SIGNALS.map do |sig|
          sig.downcase.to_sym
        end

        syms << RESTART_ACTION.downcase.to_sym
      end
    end

    def initialize(filters, action = nil)
      @filters = filters
      @action = self.class.normalize_action(action || DEFAULT_ACTION)

      raise "Expected a Hash, got '#{filters}'" unless @filters.is_a?(Hash)
      raise "Invalid container action '#{action}'" unless self.class.valid_action?(@action)

      if uses_restart?
        @container_method = :restart
        @container_params = { t: 10 }
      else
        @container_method = :kill
        @container_params = { signal: "SIG#{action}" }
      end
    end

    def uses_restart?
      @action == RESTART_ACTION
    end

    def uses_kill?
      !uses_restart?
    end

    def collect
      Docker::Container.all(all: true, filters: @filters.to_json).map do |cont|
        ContainerNotify::Action.new(cont, @container_method, @container_params)
      end
    end
  end
end
