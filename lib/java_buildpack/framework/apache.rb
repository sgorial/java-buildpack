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
        #puts `#{@droplet.sandbox}/bin/apachectl start`
      end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
        true
      end

      def expand(file)
        with_timing "Expanding Apache to #{@droplet.sandbox.relative_path_from(@droplet.root)}" do
          FileUtils.mkdir_p @droplet.sandbox + 'source'
          FileUtils.mkdir_p @droplet.sandbox + 'apache'
          FileUtils.mkdir_p @droplet.sandbox + 'pcre'
          shell "tar xzf #{file.path} -C #{@droplet.sandbox}/source --strip 1 2>&1"
          
          cd(@droplet.sandbox)
          
          puts `wget https://ftp.gnu.org/gnu/libtool/libtool-1.5.6.tar.gz`
          puts `tar -xvzf libtool-1.5.6.tar.gz`
          cd(@droplet.sandbox + 'libtool-1.5.6')
          puts `./configure`
          puts `make`
          puts `make install`
          
          cd(@droplet.sandbox)

          puts `wget http://sourceforge.net/projects/pcre/files/pcre/8.36/pcre-8.36.tar.gz`
          puts `tar -xvzf pcre-8.36.tar.gz`
          cd(@droplet.sandbox + 'pcre-8.36')
          puts `./configure --prefix=#{@droplet.sandbox}/pcre`
          puts `make`
          puts `make install`
          
          # Move back to soure root directory for make install
          cd(@droplet.sandbox + 'source')

          # Install core libraries via make utility
          #puts `./configure --prefix=#{@droplet.sandbox}/apache --with-apr=/usr/local/apr-httpd/ --with-apr-util=/usr/local/apr-util-httpd/`
          puts `./configure --prefix=#{@droplet.sandbox}/apache --with-included-apr --with-pcre=#{@droplet.sandbox}/pcre/bin/pcre-config`
          puts `make`
          puts `make install`
          puts `touch #{@droplet.sandbox}/apache/logs/access_log`
          puts `touch #{@droplet.sandbox}/apache/logs/error_log`
          
          # Overlay http.conf from resources for Apache to listen on port 80
          @droplet.copy_resources(@droplet.sandbox + 'apache')
          
          # Search and replace Listen port with VCAP_PORT variable
          puts `sed -i \'s/VCAP_PORT/#{$PORT}/g\' #{@droplet.sandbox}/apache/conf/httpd.conf`
          
          # Finally bring up Apache server
          puts `sh -x #{@droplet.sandbox}/apache/bin/httpd -DNO_DETACH`

          puts "Done installing Apache and copying resources"
        end
      end

      private

    end

  end
end
