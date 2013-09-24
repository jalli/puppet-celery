class celery::mq($user="some_user",
                 $vhost=$fqdn,
                 $password="CHANGEME",
                 $force='false') {

  class { 'rabbitmq::repo::apt':
    before => Class['rabbitmq']
  }

  class { 'rabbitmq':
    delete_guest_user => true,
  }

  # Force deletes existing config/users and re-creates
  if $force == 'true' {
      rabbitmq_user { $user:
        ensure => absent,
      }
  }

  }
  rabbitmq_user { $user:
    admin => true,
    password => $password,
    #provider => 'rabbitmqctl',
  }

  rabbitmq_vhost { $vhost:
    ensure => present,
    #provider => 'rabbitmqctl',
  }

  rabbitmq_user_permissions { "${user}@${vhost}":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
    #    provider => 'rabbitmqctl',
  }
}

class celery::server($requirements="/tmp/celery-requirements.txt",
                     $requirements_template="celery/requirements.txt",
                     $initd_template="celery/init.d.sh",
                     $config_template="celery/celeryconfig.py",
                     $defaults_template="celery/defaults.sh",
                     $broker_user="some_user",
                     $broker_vhost="some_vhost",
                     $broker_password="CHANGEME",
                     $broker_host="localhost",
                     $broker_port="5672") {

  file { $requirements:
    ensure => "present",
    content => template($requirements_template),
  }

  pip::install {"celery":
    requirements => $requirements,
    require => [Package["python-pip"], File[$requirements],],
  }

  file { "/etc/default/celeryd":
    ensure => "present",
    content => template($defaults_template),
  }

  file { "/etc/init.d/celeryd":
    ensure => "present",
    content => template($initd_template),
    mode => "0755",
  }

  user { "celery":
    ensure => "present",
  }

  file { "/var/celery":
    ensure => "directory",
    owner => "celery",
    require => User["celery"],
  }

  file { "/var/celery/celeryconfig.py":
    ensure => "present",
    replace = $force ? {
      'true'=> true, # Replace if force is set
      'false' => false, # Otherwise preserve existing
      }
    content => template($config_template),
    require => File["/var/celery"],
  }

  file { "/var/log/celery":
    ensure => "directory",
    owner => "celery",
  }

  file { "/var/run/celery":
    ensure => "directory",
    owner => "celery",
  }

  service { "celeryd":
    ensure => "running",
    require => [File["/var/celery/celeryconfig.py"],
                File["/etc/init.d/celeryd"],
                Exec["pip-celery"],
                File["/var/log/celery"],
                File["/var/run/celery"],
                Class["rabbitmq::service"], ],
  }
}

class celery::django($requirements="/tmp/celery-django-requirements.txt",
                     $requirements_template="celery/django-requirements.txt",
                     $initd_template="celery/init.d.sh",
                     $config_template="celery/celeryconfig.py",
                     $defaults_template="celery/defaults.sh",
                     $broker_user="some_user",
                     $broker_vhost="some_vhost",
                     $broker_password="CHANGEME",
                     $broker_host="localhost",
                     $broker_port="5672") {

  file { $requirements:
    ensure => "present",
    content => template($requirements_template),
  }

  pip::install {"celery":
    requirements => $requirements,
    require => [Package["pip"], File[$requirements],],
  }
}
