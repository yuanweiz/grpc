# Copyright 2015 gRPC authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
"""The Python implementation of the GRPC interoperability test client."""

import os
import sys

#from absl import app
import gevent
#from absl.flags import argparse_flags
#from google import auth as google_auth
#from google.auth import jwt as google_auth_jwt
#import grpc
#
#from src.proto.grpc.testing import test_pb2_grpc
#from tests.interop import methods
#from tests.interop import resources

if __name__ == "__main__":
    print('system version: {}'.format(sys.version))
