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
        [
          "$PWD/.java-buildpack/apache/httpd/bin/httpd -DNO_DETACH -p $PORT"
        ].flatten.compact.join(' ')
      end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
        true
      end

      def expand(file)
        with_timing "Expanding Apache to #{@droplet.sandbox.relative_path_from(@droplet.root)}" do
          FileUtils.mkdir_p @droplet.sandbox + 'httpd'
          
          cd(@droplet.sandbox)
         
          # compile Apache HTTPd from source
          puts `wget https://s3.amazonaws.com/covisintrnd.com-software/httpd-2.2.29.tar.gz`
          puts `tar -xzvf httpd-2.2.29.tar.gz`
          
          cd(@droplet.sandbox + "httpd-2.2.29")
          puts `./configure --prefix=#{@droplet.sandbox}/httpd --enable-mods-shared=all --enable-http --enable-deflate --enable-expires --enable-slotmem-shm --enable-headers --enable-rewrite --enable-proxy --enable-proxy-balancer --enable-proxy-http --enable-proxy-fcgi --enable-mime-magic --enable-log-debug --enable-so --with-expat=builtin --with-mpm=event --with-included-apr`
          puts `make`
          puts `make install`
          puts `chmod -R uog+rx #{@droplet.sandbox}/httpd`
          puts `touch #{@droplet.sandbox}/httpd/logs/access_log`
          puts `touch #{@droplet.sandbox}/httpd/logs/error_log`
          
          # Overlay http.conf from resources for Apache to listen on port 80
          @droplet.copy_resources(@droplet.sandbox + 'httpd')
          
          puts "Done installing Apache and copying resources"
        end
      end

      private

    end

  end
end
