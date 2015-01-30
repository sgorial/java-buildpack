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
          # Search and replace Listen port with VCAP_PORT variable
          #puts `for var in \`env|cut -f1 -d=\`; do echo "PassEnv \$var" >> #{@droplet.sandbox}/apache/conf/httpd.conf; done`
          puts `sed -i \'s/Listen 80/Listen #{$PORT}/g\' #{@droplet.sandbox}/apache/conf/httpd.conf`
          puts `sed -i \'s/Listen 12.34.56.78:80/Listen #{$PORT}/g\' #{@droplet.sandbox}/apache/conf/httpd.conf`
          puts `cat #{@droplet.sandbox}/apache/conf/httpd.conf`
          # Finally bring up Apache server
          puts `exec #{@droplet.sandbox}/apache/bin/httpd -DNO_DETACH`
      end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
        true
      end

      def expand(file)
        with_timing "Expanding Apache to #{@droplet.sandbox.relative_path_from(@droplet.root)}" do
          FileUtils.mkdir_p @droplet.sandbox + 'apache'
          
          cd(@droplet.sandbox)
         
          # compile Apache HTTPd from source
          puts `wget https://s3.amazonaws.com/covisintrnd.com-software/httpd-2.2.29.tar.gz`
          puts `tar -xzvf httpd-2.2.29.tar.gz`
          cd(@droplet.sandbox + "httpd-2.2.29")
          puts `./configure --prefix=#{@droplet.sandbox}/apache --enable-mods-shared=all --enable-http --enable-deflate --enable-expires --enable-slotmem-shm --enable-headers --enable-rewrite --enable-proxy --enable-proxy-balancer --enable-proxy-http --enable-proxy-fcgi --enable-mime-magic --enable-log-debug --enable-so --with-expat=builtin --with-mpm=event --with-included-apr`
          puts `make`
          puts `make install`
          puts `chmod -R uog+rx #{@droplet.sandbox}/apache`
          puts `touch #{@droplet.sandbox}/apache/logs/access_log`
          puts `touch #{@droplet.sandbox}/apache/logs/error_log`
          
          # Overlay http.conf from resources for Apache to listen on port 80
          @droplet.copy_resources(@droplet.sandbox + 'apache')
          
          cd(@droplet.sandbox)
          #puts `wget https://s3.amazonaws.com/covisintrnd.com-software/tomcat-connectors-1.2.40-src.tar.gz`
          #puts `tar -xzvf tomcat-connectors-1.2.40-src.tar.gz`
          #cd(@droplet.sandbox + "tomcat-connectors-1.2.40-src" + "native")
          #puts `./configure --with-apxs=#{@droplet.sandbox}/apache/bin/apxs && make && make install`
          
          # Search and replace Listen port with VCAP_PORT variable
          #puts `for var in \`env|cut -f1 -d=\`; do echo "PassEnv \$var" >> /app/${APACHE_PATH}/conf/httpd.conf; done`
          #puts `sed -i \'s/VCAP_PORT/#{$PORT}/g\' /app/apache/conf/httpd.conf`
          #puts `cat /app/apache/conf/httpd.conf`
          # Finally bring up Apache server
          #puts `exec #{@droplet.sandbox}/apache/bin/httpd -DNO_DETACH`

          puts "Done installing Apache and copying resources"
        end
      end

      private

    end

  end
end
