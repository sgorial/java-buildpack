require 'fileutils'
require 'java_buildpack/component/base_component'
require 'java_buildpack/container'
require 'java_buildpack/container/tomcat/tomcat_utils'
include FileUtils

module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for the Apache web server.
    class ApacheHttpdInstance < JavaBuildpack::Component::BaseComponent
      include JavaBuildpack::Container

      # (see JavaBuildpack::Component::BaseComponent#detect)
      def detect
      end

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        with_timing "Expanding Apache HTTPd to #{@droplet.sandbox.relative_path_from(@droplet.root)}" do
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
          
          cd(@droplet.sandbox)
          puts `rm -rf httpd-2.2.29/`
          
          # Overlay http.conf from resources for Apache to listen on port 80
          @droplet.copy_resources(@droplet.sandbox + 'httpd')
          
          puts `ls -alrt #{@droplet.sandbox}`
          
          puts "Done installing Apache and copying resources"
        end
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
      end

    end

  end
end
