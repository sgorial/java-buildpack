require 'fileutils'
require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/framework'
include FileUtils

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
        #puts `/etc/init.d/apache2 status`
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
          
          cd(@droplet.sandbox + 'srclib')

          puts ""
          puts "Begin Apache2 HTTPD installation..."

          # APR
          puts `wget http://mirrors.axint.net/apache//apr/apr-1.4.6.tar.gz`
          puts `tar -xvzf apr-1.4.6.tar.gz`
          puts `mv apr-1.4.6/ apr/`

          # APR Utils
          puts `wget http://mirrors.axint.net/apache//apr/apr-util-1.4.1.tar.gz`
          puts `tar -xvzf apr-util-1.4.1.tar.gz`
          puts `mv apr-util-1.4.1/ apr-util/`

          # Move back to root app directory for make install
          cd(@droplet.sandbox)
          
          puts `./configure --prefix=#{@droplet.sandbox}`
          puts `make`
          puts `make install`
          
          # CD to prefix -> where we configured Apache's installation path
          cd(@droplet.sandbox)
          
          # Finally bring up the server
          puts `bin/apachectl start`
          
          @droplet.copy_resources
        end
      end

      private

    end

  end
end
