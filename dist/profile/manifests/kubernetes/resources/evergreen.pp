#   Class: profile::kubernetes::resources::evergreen
#
#   This class deploys the Jenkins Essentials backend service layer, a
#   container which communicates with a provisioned Azure PostgreSQL database
#
class profile::kubernetes::resources::evergreen (
    Array $clusters = $profile::kubernetes::params::clusters,
    Array $domain_alias = [],
    String $image_tag = 'latest',
    String $domain_name = 'evergreen.jenkins.io',
    String $postgres_url = '',
) inherits profile::kubernetes::params {

  require profile::kubernetes::kubectl
  require profile::kubernetes::resources::nginx
  require profile::kubernetes::resources::lego

  $clusters.each | $cluster | {
    $context = $cluster['clustername']

    file { "${profile::kubernetes::params::resources}/${context}/evergreen":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    profile::kubernetes::apply { "evergreen/service.yaml on ${context}":
      context  => $context,
      resource => 'evergreen/service.yaml'
    }

    profile::kubernetes::apply { "evergreen/secret.yaml on ${context}":
      context    => $context,
      parameters => {
      },
      resource   => 'evergreen/secret.yaml'
    }

    profile::kubernetes::apply { "evergreen/ingress-tls.yaml on ${context}":
      context    => $context,
      parameters => {
        'url'     => $domain_name,
        'aliases' => $domain_alias
      },
      resource   =>  'evergreen/ingress-tls.yaml'
    }

    profile::kubernetes::apply { "evergreen/deployment.yaml on ${context}":
      context    => $context,
      parameters => {
      },
      resource   => 'evergreen/deployment.yaml'
    }

    profile::kubernetes::reload { "evergreen pods on ${context}":
      app        => 'evergreen',
      context    => $context,
      depends_on => [
        'evergreen/secret.yaml'
      ]
    }

    profile::kubernetes::backup { "evergreen-tls on ${context}":
      context =>  $context
    }
  }
}
