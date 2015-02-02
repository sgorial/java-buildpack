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

require 'java_buildpack/component/modular_component'
require 'java_buildpack/container'
require 'java_buildpack/container/tomcat/tomcat_insight_support'
require 'java_buildpack/container/tomcat/tomcat_instance'
require 'java_buildpack/container/tomcat/tomcat_lifecycle_support'
require 'java_buildpack/container/tomcat/tomcat_logging_support'
require 'java_buildpack/container/tomcat/tomcat_access_logging_support'
require 'java_buildpack/container/tomcat/tomcat_redis_store'
require 'java_buildpack/container/tomcat/apache'

module JavaBuildpack
  module Container

    # Encapsulates the detect, compile, and release functionality for Tomcat applications.
    class Tomcat < JavaBuildpack::Component::ModularComponent

      protected

      # (see JavaBuildpack::Component::ModularComponent#command)
      def command
        @droplet.java_opts.add_system_property 'http.port', '8080'

        [
          @droplet.java_home.as_env_var,
          @droplet.java_opts.as_env_var,
          "$PWD/.java-buildpack/apache/httpd/bin/httpd -DNO_DETACH -p $PORT",
          "$PWD/#{(@droplet.sandbox + 'bin/catalina.sh').relative_path_from(@droplet.root)}",
          'run'
        ].flatten.compact.join(' ')
      end

      # (see JavaBuildpack::Component::ModularComponent#sub_components)
      def sub_components(context)
        [
          ApacheHttpdInstance.new(sub_configuration_context(context, 'apache')),
          TomcatInstance.new(sub_configuration_context(context, 'tomcat')),
          TomcatLifecycleSupport.new(sub_configuration_context(context, 'lifecycle_support')),
          TomcatLoggingSupport.new(sub_configuration_context(context, 'logging_support')),
          TomcatAccessLoggingSupport.new(sub_configuration_context(context, 'access_logging_support')),
          TomcatRedisStore.new(sub_configuration_context(context, 'redis_store')),
          TomcatInsightSupport.new(context)
        ]
      end

      # (see JavaBuildpack::Component::ModularComponent#supports?)
      def supports?
        web_inf? && !JavaBuildpack::Util::JavaMainUtils.main_class(@application)
      end

      private

      def web_inf?
        (@application.root + 'WEB-INF').exist?
      end

    end

  end
end
