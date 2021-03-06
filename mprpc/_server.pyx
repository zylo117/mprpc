# cython: profile=False
# -*- coding: utf-8 -*-

import os

if 'nt' not in os.name:
    import signal

import gevent.socket
import msgpack
import msgpack_numpy as m
m.patch()

from mprpc.constants import MSGPACKRPC_REQUEST, MSGPACKRPC_RESPONSE
from mprpc.exceptions import MethodNotFoundError, RPCProtocolError
from gevent.local import local

cdef int _timeout

cdef class _RPCServer:
    """
    RPC server.

    :param dict pack_params: (optional) Parameters to pass to Messagepack Packer
    :param dict unpack_params: (optional) Parameters to pass to Messagepack
        Unpacker

    Usage:
        >>> from mprpc import RPCServer
        >>>
        >>> class SumServer:
        ...     def sum(self, x, y):
        ...         return x + y
        ...
        >>>
        >>> server = RPCServer('127.0.0.1', 6000, SumServer())
        >>> server.serve_forever()
    """

    cdef _packer
    cdef _unpack_params
    cdef bint _tcp_no_delay
    cdef dict _methods
    cdef _address

    cdef bint _debug
    cdef bint _is_available
    cdef int _buffer_size

    def __init__(self, *args, **kwargs):
        pack_encoding = kwargs.pop('pack_encoding', 'utf-8')
        pack_params = kwargs.pop('pack_params', dict(use_bin_type=True))

        self._unpack_params = kwargs.pop('unpack_params', dict(use_list=False))

        # add debug mode, print req/res
        self._debug = kwargs.pop('debug', False)

        # record working status
        self._is_available = True

        # set per call timeout
        if 'timeout' in kwargs and 'nt' in os.name:
            raise OSError('Windows does not support signal, remove timeout argument and try again.')

        if 'nt' not in os.name:
            global _timeout
            _timeout = kwargs.pop('timeout', 10)
            signal.signal(signal.SIGALRM, timeout)
        else:
            self._call = self._call_nt

        # add socket buffer_size
        self._buffer_size = kwargs.pop('buffer_size', 1024 ** 2)

        self._tcp_no_delay = kwargs.pop('tcp_no_delay', False)
        self._methods = {}

        self._packer = msgpack.Packer(**pack_params)

        self._address = local()
        self._address.client_host = None
        self._address.client_port = None

        if args and isinstance(args[0], gevent.socket.socket):
            self._run(_RPCConnection(args[0]))

    def __call__(self, sock, address):
        if self._tcp_no_delay:
            sock.setsockopt(gevent.socket.IPPROTO_TCP, gevent.socket.TCP_NODELAY, 1)

        self._address.client_host = address[0]
        self._address.client_port = address[1]

        self._run(_RPCConnection(sock))

    property client_host:
        def __get__(self):
            return self._address.client_host

    property client_port:
        def __get__(self):
            return self._address.client_port

    def _run(self, _RPCConnection conn):
        cdef bytes data
        cdef int msg_id

        unpacker = msgpack.Unpacker(raw=False, **self._unpack_params)
        while True:
            data = conn.recv(self._buffer_size)
            if not data:
                break

            unpacker.feed(data)
            try:
                req = next(unpacker)
            except StopIteration:
                continue

            if type(req) not in (tuple, list):
                self._send_error("Invalid protocol", -1, conn)
                # reset unpacker as it might have garbage data
                unpacker = msgpack.Unpacker(raw=False, **self._unpack_params)
                continue

            (msg_id, method, args) = self._parse_request(req)

            try:
                if method != self.is_available:
                    # set status to not available
                    self._is_available = False

                # ret = method(*args)
                ret = self._call(method, *args)

            except Exception, e:
                self._send_error(str(e), msg_id, conn)

            else:
                self._send_result(ret, msg_id, conn)

            finally:
                # set status to available
                if method != self.is_available:
                    # set status to not available
                    self._is_available = True

    def _call(self, method, *args):
        signal.alarm(_timeout)
        ret = method(*args)
        signal.alarm(0)
        return ret

    def _call_nt(self, method, *args):
        ret = method(*args)
        return ret

    cdef tuple _parse_request(self, req):
        if (len(req) != 4 or req[0] != MSGPACKRPC_REQUEST):
            raise RPCProtocolError('Invalid protocol')

        cdef int msg_id
        cdef str method_name
        cdef tuple args

        (_, msg_id, method_name, args) = req
        if self._debug:
            print(f'req: msg_id: {msg_id}, method_name: {method_name}, args:{args}')

        method = self._methods.get(method_name, None)

        if method is None:
            if method_name.startswith('_'):
                raise MethodNotFoundError('Method not found: %s', method_name)

            if not hasattr(self, method_name):
                raise MethodNotFoundError('Method not found: %s', method_name)

            method = getattr(self, method_name)

            if not hasattr(method, '__call__'):
                raise MethodNotFoundError('Method is not callable: %s', method_name)

            # caching method for faster call
            self._methods[method_name] = method

        return (msg_id, method, args)

    def is_available(self):
        return self._is_available

    cdef _send_result(self, object result, int msg_id, _RPCConnection conn):
        msg = (MSGPACKRPC_RESPONSE, msg_id, None, result)

        if self._debug:
            print(f'res: msg: {msg}')

        conn.send(self._packer.pack(msg))

    cdef _send_error(self, str error, int msg_id, _RPCConnection conn):
        msg = (MSGPACKRPC_RESPONSE, msg_id, error, None)
        conn.send(self._packer.pack(msg))

cdef class _RPCConnection:
    cdef _socket

    def __init__(self, socket):
        self._socket = socket

    cdef recv(self, int buf_size):
        return self._socket.recv(buf_size)

    cdef send(self, bytes msg):
        self._socket.sendall(msg)

    def __del__(self):
        try:
            self._socket.close()
        except:
            pass


def timeout(signum, frame):
    raise TimeoutError('failed to return result after timeout reached for {} seconds'.format(_timeout))
