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
          FileUtils.mkdir_p @droplet.sandbox + 'source'
          FileUtils.mkdir_p @droplet.sandbox + 'server'
          shell "tar xzf #{file.path} -C #{@droplet.sandbox}/source --strip 1 --exclude webapps 2>&1"
          
          cd(@droplet.sandbox)
          
          puts `wget https://ftp.gnu.org/gnu/libtool/libtool-1.5.6.tar.gz`
          puts `tar -xvzf libtool-1.5.6.tar.gz`
          cd(@droplet.sandbox + 'libtool-1.5.6')
          puts `./configure`
          puts `make`
          puts `make install`
          
          cd(@droplet.sandbox + 'source/srclib')

          # APR
          puts `wget http://mirrors.axint.net/apache//apr/apr-1.4.6.tar.gz`
          puts `tar -xvzf apr-1.4.6.tar.gz`
          puts `mv apr-1.4.6/ apr/`
          cd(@droplet.sandbox + 'source/srclib/apr')
          puts `./configure --prefix=/usr/local/apr-httpd/`
          puts `make`
          puts `make install`

          cd(@droplet.sandbox + 'source/srclib')

          # APR Utils
          puts `wget http://mirrors.axint.net/apache//apr/apr-util-1.4.1.tar.gz`
          puts `tar -xvzf apr-util-1.4.1.tar.gz`
          puts `mv apr-util-1.4.1/ apr-util/`
          cd(@droplet.sandbox + 'source/srclib/apr-util')
          puts `./configure --prefix=/usr/local/apr-util-httpd/ --with-apr=/usr/local/apr-httpd/`
          puts `make`
          puts `make install`

          # Move back to root app directory for make install
          cd(@droplet.sandbox + 'source')

          puts ""
          puts "Begin Apache2 HTTPD installation..."
          
          # Install core libraries via make utility
          puts `./configure --prefix=#{@droplet.sandbox}/server --with-apr=/usr/local/apr-httpd/ --with-apr-util=/usr/local/apr-util-httpd/`
          puts `make`
          puts `make install`
          
          #cd(@droplet.sandbox + 'server')
          # Finally bring up the server
          #puts `./bin/apachectl start`
          
          # Overlay custom http.conf file from resources (configured to listen on port 80)
          #@droplet.copy_resources
        end
      end

      private

    end

  end
end
