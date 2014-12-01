require 'java_buildpack/component/versioned_dependency_component'

module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for Tomcat logging support.
    class TomcatLoggingSupport < JavaBuildpack::Component::VersionedDependencyComponent

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        download_jar(jar_name, endorsed)
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
      end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
        true
      end

      private

      def endorsed
        @droplet.sandbox + 'endorsed'
      end

      def jar_name
        "tomcat_logging_support-#{@version}.jar"
      end

    end

  end
end
