mprpc
=====

.. image:: https://badge.fury.io/py/mprpc.png
    :target: http://badge.fury.io/py/mprpc

.. image:: https://travis-ci.org/studio-ousia/mprpc.png?branch=master
    :target: https://travis-ci.org/studio-ousia/mprpc

mprpc is a lightweight `MessagePack RPC <https://github.com/msgpack-rpc/msgpack-rpc>`_ library. It enables you to easily build a distributed server-side system by writing a small amount of code. It is built on top of `gevent <http://www.gevent.org/>`_ and `MessagePack <http://msgpack.org/>`_.

This repo adapt to the newest msgpack with a little bit speedup and add numpy support.

Also, this repo has unified the RPCServer and RPCClient usage, making it easier to use.

Installation
------------

To install mprpc, simply:

.. code-block:: bash

    $ pip install git+https://github.com/zylo117/mprpc


Examples
--------

RPC server
^^^^^^^^^^

.. code-block:: python

New Style (no need to inherit RPCServer explicitly)

.. code-block:: python

    from mprpc import RPCServer

    class SumServer:
        def sum(self, x, y):
            return x + y

    server = RPCServer('127.0.0.1', 6000, SumServer())
    server.serve_forever()


Original Style (Not Recommended)

.. code-block:: python

    from gevent.server import StreamServer
    from mprpc._server import _RPCServer

    class SumServer(_RPCServer):
        def sum(self, x, y):
            return x + y

    server = StreamServer(('127.0.0.1', 6000), SumServer())
    server.serve_forever()



RPC client
^^^^^^^^^^

.. code-block:: python

    from mprpc import RPCClient

    client = RPCClient('127.0.0.1', 6000)
    print client.call('sum', 1, 2)


RPC client with connection pooling (generally you don't need it)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: python

    import gsocketpool.pool
    from mprpc import RPCPoolClient

    client_pool = gsocketpool.pool.Pool(RPCPoolClient, dict(host='127.0.0.1', port=6000))

    with client_pool.connection() as client:
        print client.call('sum', 1, 2)


Performance
-----------

mprpc significantly outperforms the `official MessagePack RPC <https://github.com/msgpack-rpc/msgpack-rpc-python>`_ (**1.8x** faster), which is built using `Facebook's Tornado <http://www.tornadoweb.org/en/stable/>`_ and `MessagePack <http://msgpack.org/>`_, and `ZeroRPC <http://zerorpc.dotcloud.com/>`_ (**14x** faster), which is built using `ZeroMQ <http://zeromq.org/>`_ and `MessagePack <http://msgpack.org/>`_.

While this repo has adapt to the newest msgpack with a few of extra features, it's a little bit faster than the original mprpc.

Personal perspective: zerorpc was my personal favorite before this repo. Though zerorpc use zeromq as middleware, which provides a more stable communication for rpc and even better, auto load balancing, it brings a lots of overhead along with it.

Besides, this repo is cython optimized, yet zerorpc is not. So this benchmark it's not entirely fair.

While using mprpc, you should pay attention to the load balancing and job distribution, which might be the real bottleneck someday.


Results
^^^^^^^

.. image::  https://raw.githubusercontent.com/zylo117/mprpc/master/docs/img/pefr.png
    :width: 600px
    :height: 200px
    :alt: Performance Comparison

Environment:

Intel i5-8400

Ubuntu 19.10 Desktop x64 (5.3.0-21-generic)

Python3.7

Documentation
-------------

Documentation is available at http://mprpc.readthedocs.org/.
