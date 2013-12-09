class celery(
    $celeryd_multi_binary ="/usr/local/bin/celeryd-multi",
    $celery_binary="/usr/local&/bin/celery"
             ) {
    include sddlib
}

class celery::mq($user="some_user",
                 $vhost=$fqdn,
                 $password="CHANGEME") {
  include stdlib
  # Load python module with virtualenv support and python dev env
  ensure_resource('class', 'python', {'version' => 'system', 'dev' => true, 'virtualenv' => true, 'pip' => true })

  class { 'rabbitmq':
    delete_guest_user => true,
  }

  rabbitmq_user { $user:
    admin => true,
    password => $password,
  }

  rabbitmq_vhost { $vhost:
    ensure => present,
  }

  rabbitmq_user_permissions { "${user}@${vhost}":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
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

  python::requirements { $requirements: }
  python::pip {"celery":
    require => [Package["python-pip"], Python::Requirements[$requirements]],
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
    content => template($config_template),
    require => File["/var/celery"],
    replace => false, # Current rabbitmq does not validate user, workarround so that password never gets ovewritten
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
                Exec["pip_install_celery"],
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

  python::requirements { $requirements: }
  python::pip {"celery":
    require => [Package["pip"], Python::Requirements[$requirements]],
  }
}
