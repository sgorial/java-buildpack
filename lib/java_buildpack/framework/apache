require 'fileutils'
require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/framework'

module JavaBuildpack
  module Framework

    # Encapsulates the functionality for enabling zero-touch Apache support.
    class Apache < JavaBuildpack::Component::VersionedDependencyComponent

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        puts `uname -a`
        download(@version, @uri) { |file| expand file }
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
      end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
        true
      end

      def expand(file)
        with_timing "Expanding Apache to #{@droplet.sandbox.relative_path_from(@droplet.root)}" do
          FileUtils.mkdir_p @droplet.sandbox
          shell "tar xzf #{file.path} -C #{@droplet.sandbox} --strip 1 --exclude webapps 2>&1"

          @droplet.copy_resources
        end
      end

      private

    end

  end
end
