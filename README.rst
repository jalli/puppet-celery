celery for puppet
=================
This installs and configures `Celery`_.

This is a `puppet`_ module that uses Python's `pip`_.  Puppet has a
built-in pip provider, but it's implementation leaves out a few pieces:

* No ability to install from requirements file.
* No ability to add extra arguments
* No support for using mirrors or specifying alternate indexes.

This module uses the puppet-python module to get around these limitations.


Usage
-----
Make sure this module is available by adding this repository's contents
in a directory called ``celery`` inside your Puppet's ``moduledir``.
It also requires the `puppet-python`_ module and `puppet-stdlib` as well.


Bootstrapping RabbitMQ
""""""""""""""""""""""
If you need to bootstrap RabbitMQ (note that this requires that you have
`this version`_ of `puppetlabs-rabbitmq`_ to run on RabbitMQ 2.6)::

    class { "celery::mq": }

You should provide a ``user``, ``vhost``, and ``password`` along these
lines::

    class { "celery::mq":
      $user => "myuser",
      $vhost => "myvhost",
      $password => "secret",
    }

This installs and configures RabbitMQ.  Take a look at
`puppetlabs-rabbitmq`_ if you need more flexibility in how your RabbitMQ
instance is initialized.

Creating Celery Server
""""""""""""""""""""""
You create a celery server with the ``celery::server`` class like this::

    class { "celery::server": }

If you're relying on the RabbitMQ bootstrap, you would set it up like this::

    class { "celery::server":
      require => Class["celery::mq"],
    }

Configuration
-------------
The module also includes two .erb templates for sudo files enabling non-root
users to manage the celery and celerybeat services.

In order to use the templates it's recommended to use the `saz/sudo` module and
configuration similar to::

    class {'sudo':}
    include celery
    $celeryd_multi_binary = $celery::celeryd_multi_binary
    $celery_binary = $celery::celery_binary
    $broker_user = 'celery´

    # Create sudo records to stop/start celery as admin user without password
    sudo::conf { "celery":
        priority => 03,
        content => template('celery/admin_user_sudoers.erb','celery/admin_group_sudoers.erb'),
        require => Class['celery::mq']
    }

    # Sudo with password for all other commands than celery
    # Should always come after the previous record, otherwise user will always
    # be asked for password
    sudo::conf { $admin_user:
        priority => 01,
        content  => "${admin_user} ALL=(ALL) ALL\n",
    }

.. _Celery: http://celeryproject.org/
.. _distribute: http://packages.python.org/distribute/
.. _pip: http://www.pip-installer.org/
.. _puppet: http://puppetlabs.com/
.. _puppet-pip: https://github.com/armstrong/puppet-pip
.. _puppetlabs-rabbitmq: https://github.com/puppetlabs/puppetlabs-rabbitmq/
.. _this version: https://github.com/puppetlabs/puppetlabs-rabbitmq/pull/8
