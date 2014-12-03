# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fileutils'
require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/container'
include FileUtils

module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for the Tomcat instance.
    class Apache < JavaBuildpack::Component::VersionedDependencyComponent
      include JavaBuildpack::Container

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        download(@version, @uri) { |file| expand file }
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
        puts `./#{@droplet.sandbox}/apache/bin/apachectl start`
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
          shell "tar xzf #{file.path} -C #{@droplet.sandbox}/source --strip 1 --exclude webapps 2>&1"
          
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
          
          # Overlay http.conf from resources for Apache to listen on port 80
          @droplet.copy_resources(@droplet.sandbox + 'apache')
          
          puts "Done installing Apache and copying resources"
        end
      end

      private

    end

  end
end
