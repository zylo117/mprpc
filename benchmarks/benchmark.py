# -*- coding: utf-8 -*-
import time
import multiprocessing
import numpy as np

NUM_CALLS = 10000

img = np.array([1080, 1920, 3])


def run_sum_server():
    from mprpc import RPCServer

    class SumServer:
        def sum(self, x, y):
            return x

    server = RPCServer('127.0.0.1', 7777, SumServer())
    server.serve_forever()


def call():
    from mprpc import RPCClient

    client = RPCClient('127.0.0.1', 7777)

    t = np.zeros(NUM_CALLS)

    for _ in range(NUM_CALLS):
        t1 = time.time()
        client.call('sum', 1, 2)
        t2 = time.time()
        t[_] = t2 - t1

    print('stdev: {}'.format(t.std()))
    print('mean: {}'.format(t.mean()))
    print('call: {} qps'.format(1 / t.mean()))


def call_using_connection_pool():
    from mprpc import RPCPoolClient

    import gevent.pool
    import gsocketpool.pool

    def _call(n):
        with client_pool.connection() as client:
            return client.call('sum', 1, 2)

    options = dict(host='127.0.0.1', port=7777)
    client_pool = gsocketpool.pool.Pool(RPCPoolClient, options, initial_connections=20)
    glet_pool = gevent.pool.Pool(20)

    start = time.time()

    [None for _ in glet_pool.imap_unordered(_call, range(NUM_CALLS))]

    print('call_using_connection_pool: %d qps' % (NUM_CALLS / (time.time() - start)))


if __name__ == '__main__':
    p = multiprocessing.Process(target=run_sum_server)
    p.start()

    time.sleep(1)

    call()
    call_using_connection_pool()

    p.terminate()
