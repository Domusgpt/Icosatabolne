cmake_minimum_required(VERSION 3.14)
project(vib3_flutter_library VERSION 2.0.1 LANGUAGES CXX)

add_library(vib3_flutter SHARED
  "../src/vib3_ffi.cpp"
)

target_include_directories(vib3_flutter PUBLIC
  "../src"
)

set_target_properties(vib3_flutter PROPERTIES
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED ON
  OUTPUT_NAME "vib3_flutter"
)

target_compile_definitions(vib3_flutter PRIVATE FLUTTER_PLUGIN_IMPL)

set(vib3_flutter_bundled_libraries
  "$<TARGET_FILE:vib3_flutter>"
  PARENT_SCOPE
)
