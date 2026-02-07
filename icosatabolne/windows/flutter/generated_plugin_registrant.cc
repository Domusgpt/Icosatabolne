//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <audioplayers_windows/audioplayers_windows_plugin.h>
#include <vib3_flutter/vib3_flutter_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  AudioplayersWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("AudioplayersWindowsPlugin"));
  Vib3FlutterPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("Vib3FlutterPluginCApi"));
}
