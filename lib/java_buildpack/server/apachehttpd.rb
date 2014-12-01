require 'fileutils'
require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/server'

module JavaBuildpack
  module Server

    # Encapsulates the detect, compile, and release functionality for selecting an ApacheHTTPD server.
    class ApacheHTTPD < JavaBuildpack::Component::VersionedDependencyComponent

      # Creates an instance
      #
      # @param [Hash] context a collection of utilities used the component
      def initialize(context)
        @application    = context[:application]
        @component_name = self.class.to_s.space_case
        @configuration  = context[:configuration]
        @droplet        = context[:droplet]

        @droplet.java_home.root = @droplet.sandbox
      end

      # (see JavaBuildpack::Component::BaseComponent#detect)
      def detect
        @version, @uri = JavaBuildpack::Repository::ConfiguredItem.find_item(@component_name, @configuration)
        @droplet.java_home.version = @version
        super
      end

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        download_tar
        @droplet.copy_resources
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
        @droplet.java_opts
        .add_system_property('java.io.tmpdir', '$TMPDIR')
        .add_option('-XX:OnOutOfMemoryError', killapache)
      end

      private

      def killapache
        @droplet.sandbox + 'bin/apachectl.sh stop'
      end

    end

  end
end
