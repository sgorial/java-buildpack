require 'java_buildpack/component/modular_component'
require 'java_buildpack/framework'
require 'java_buildpack/framework/apache'

module JavaBuildpack
  module Framework

    # Encapsulates the detect, compile, and release functionality for Tomcat applications.
    class ApacheServer < JavaBuildpack::Component::ModularComponent

      # (see JavaBuildpack::Component::ModularComponent#command)
      def command
        # @droplet.java_opts.add_system_property 'http.port', '$PORT'

        [
          @droplet.java_home.as_env_var,
          @droplet.java_opts.as_env_var,
          "$PWD/#{(@droplet.sandbox + 'apache/bin/apachectl').relative_path_from(@droplet.root)}",
          'start'
        ].flatten.compact.join(' ')
      end

      # (see JavaBuildpack::Component::ModularComponent#sub_components)
      def sub_components(context)
        [
          Apache.new(sub_configuration_context(context, 'apache'))
        ]
      end

      # (see JavaBuildpack::Component::ModularComponent#supports?)
      def supports?
        true
      end

    end

  end
end
