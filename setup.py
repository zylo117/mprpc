# -*- coding: utf-8 -*-

from setuptools import setup, Extension
from Cython.Build import cythonize
from distutils.core import setup
from Cython.Distutils import Extension

setup(name='mprpc',
      version='0.1.17',
      description='A fast MessagePack RPC library with numpy support',
      long_description=open('README.rst').read(),
      author='Studio Ousia',
      author_email='ikuya@ousia.jp',
      url='http://github.com/studio-ousia/mprpc',
      packages=['mprpc'],
      ext_modules=cythonize([
          Extension("mprpc.client", ["mprpc/client.pyx"], language="c"),
          Extension('mprpc.server', ['mprpc/server.pyx'], language="c")
      ], language_level=3),
      license=open('LICENSE').read(),
      include_package_data=True,
      keywords=[
          'rpc', 'msgpack', 'messagepack', 'msgpackrpc', 'messagepackrpc',
          'messagepack rpc', 'gevent'
      ],
      classifiers=[
          'Development Status :: 4 - Beta',
          'Intended Audience :: Developers',
          'Natural Language :: English',
          'License :: OSI Approved :: Apache Software License',
          'Programming Language :: Python',
          'Programming Language :: Python :: 2.6',
          'Programming Language :: Python :: 2.7',
          'Programming Language :: Python :: 3.3',
          'Programming Language :: Python :: 3.4',
          'Programming Language :: Python :: 3.5',
      ],
      install_requires=[
          'gsocketpool',
          'gevent',
          'msgpack-python',
          'msgpack-numpy',
      ],
      tests_require=[
          'nose',
          'mock',
      ],
      test_suite='nose.collector')
