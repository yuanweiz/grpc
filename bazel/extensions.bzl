# Copyright 2025 the gRPC authors.
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

"""
A module extension that provides wrappers for macros from bazel_toolchains
so they can be used in MODULE.bazel.
"""

load(
    "@bazel_toolchains//rules/exec_properties:exec_properties.bzl",
    "create_rbe_exec_properties_dict",
    "custom_exec_properties",
)

def _always_fail(ctx):
    fail("failed.")

_fail_properties = tag_class(attrs = {
    "name": attr.string(),
})

def _exec_properties_impl(ctx):
    debug_str = "start of debug_str\n"
    for module in ctx.modules:
        debug_str += ("module.name=" + module.name + "\n")
        repositories = {}
        for cep in module.tags.custom_exec_properties:
            name = cep.name
            constant = cep.constant
            rbe_exec_properties_dict = cep.rbe_exec_properties_dict
            debug_str += "cep.name={}\n".format(name)
            debug_str += "cep.constant={}\n".format(constant)
            debug_str += "cep.rbe_exec_properties_dict={}\n".format(repr(rbe_exec_properties_dict))
            if not name in repositories:
                repositories[name] = {}
            repositories[name][constant] = create_rbe_exec_properties_dict(
                labels = rbe_exec_properties_dict,
            )
            debug_str += "repositories[{}][{}] = {}\n".format(name, constant, repr(repositories[name][constant]))
        for name, constants in repositories.items():
            custom_exec_properties(name, constants)
    print(debug_str)

_custom_exec_properties = tag_class(attrs = {
    "name": attr.string(),
    "constant": attr.string(),
    # Might add more types later if necessary
    "rbe_exec_properties_dict": attr.string_dict(),
})

exec_properties = module_extension(
    implementation = _exec_properties_impl,
    tag_classes = {"custom_exec_properties": _custom_exec_properties},
)

always_fail = module_extension(
    implementation = _always_fail,
    tag_classes = {"fail": _fail_properties},
)
