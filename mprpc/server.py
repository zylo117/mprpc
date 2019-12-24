from gevent.server import StreamServer
from mprpc._server import _RPCServer


class RPCServer(StreamServer):
    def __init__(self, host, port, handle, debug=False, timeout=10, **kwargs):
        """
            create a RPCServer instance and warp obj with it

            Args:
                host: ip address
                port: port number
                handle: any object to be rpc
                debug: if debug, print every req/res
                timeout: per call timeout, if timeout reached, return RPCError(TimeoutError)
                **kwargs:

            Returns:

            """

        class WrappedObj(_RPCServer):
            def __init__(self, obj):
                super().__init__(WrappedObj, debug=debug, timeout=timeout, **kwargs)
                self.obj = obj

            def __getattr__(self, attr_name):
                ret = getattr(self.obj, attr_name)
                return ret

        handle = WrappedObj(handle)
        super().__init__((host, port), handle)
