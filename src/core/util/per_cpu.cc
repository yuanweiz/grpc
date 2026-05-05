// Copyright 2023 gRPC authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#include "src/core/util/per_cpu.h"

#include <grpc/support/cpu.h>
#include <grpc/support/port_platform.h>
#include <stdio.h>

#include "src/core/util/useful.h"
#include "absl/debugging/stacktrace.h"
#include "absl/debugging/symbolize.h"
#include "absl/log/log.h"

namespace grpc_core {

#ifndef GPR_CPU_CUSTOM
thread_local PerCpuShardingHelper::State PerCpuShardingHelper::state_;
#endif  // GPR_CPU_CUSTOM

void DumpStackTrace() {
  //	  const int kMaxDepth = 32;
  //  void* stack[kMaxDepth];
  //
  //  // 1. Capture the stack trace
  //  int depth = absl::GetStackTrace(stack, kMaxDepth, 1);
  //
  //  for (int i = 0; i < depth; ++i) {
  //    char symbol[1024];
  //    // 2. Symbolize each address
  //    if (absl::Symbolize(stack[i], symbol, sizeof(symbol))) {
  //      VLOG(2) << "  frame #" << i << ": " << symbol << " [" << stack[i] <<
  //      "]";
  //    } else {
  //      VLOG(2) << "  frame #" << i << ": (unknown) [" << stack[i] << "]";
  //    }
  //  }
}

size_t PerCpuOptions::Shards() {
  return ShardsForCpuCount(gpr_cpu_num_cores());
}

size_t PerCpuOptions::ShardsForCpuCount(size_t cpu_count) {
  VLOG(2) << "cpu_count: " << cpu_count;
  VLOG(2) << "cpus_per_shard_: " << cpus_per_shard_;
  VLOG(2) << "max_shards_: " << max_shards_;
  return Clamp<size_t>(cpu_count / cpus_per_shard_, 1, max_shards_);
}

}  // namespace grpc_core
