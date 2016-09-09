# Description
# -----------
#
# This cmake script searches through the plugins directory and generates the
# files device_plugin_container.h and device_plugin_container.cpp using the
# templates device_plugin_container.h.in and device_plugin_container.cpp.in.
#
# Each plugin should have the following structure:
#
# example
# ├── CMakeLists.txt
# ├── example.cpp
# ├── example.h
# ├── example_impl.cpp
# └── example_impl.h
#
# An example plugin can be found in example_plugin/
#
# example.h and example.cpp define the publicly visible interface and
# example_impl.h and example_impl.cpp contain the implementation of the
# actual plugin.

if (DEFINED EXTERNAL_DIR)
    message("External plugin folder: ${EXTERNAL_DIR}")
endif()

# This defines the plugins directory.
file(GLOB plugins plugins/*)
file(GLOB external_plugins ${EXTERNAL_DIR}/plugins/*)

# Look for plugins in plugin directory
foreach(plugin ${plugins})
    if(IS_DIRECTORY ${plugin})
        message("Found plugin ${plugin}")
        add_subdirectory(${plugin})
        foreach(source_file ${source_files})
            list(APPEND plugin_source_files "${plugin}/${source_file}")
        endforeach()
        foreach(header_file ${header_files})
            list(APPEND plugin_header_paths "${plugin}/${header_file}")
        endforeach()
        list(APPEND plugin_class_names "${class_name}")
        list(APPEND plugin_header_files "${header_files}")
        list(APPEND plugin_impl_header_files "${impl_header_files}")
    endif()
endforeach()

# Look for plugins in external plugin directory
foreach(plugin ${external_plugins})
    if(IS_DIRECTORY ${plugin})
        message("Found external plugin ${plugin}")
        add_subdirectory(${plugin} ${CMAKE_CURRENT_BINARY_DIR}/${plugin})
        foreach(source_file ${source_files})
            list(APPEND plugin_source_files "${plugin}/${source_file}")
        endforeach()
        foreach(header_file ${header_files})
            list(APPEND plugin_header_paths "${plugin}/${header_file}")
        endforeach()
        list(APPEND plugin_class_names "${class_name}")
        list(APPEND plugin_header_files "${header_files}")
        list(APPEND plugin_impl_header_files "${impl_header_files}")
    endif()
endforeach()

# Contains the #include "example.h" for the public facing files.
set(INCLUDES_STRING "")
foreach(header_file ${plugin_header_files})
    set(INCLUDES_STRING "${INCLUDES_STRING}#include \"${header_file}\"\n")
endforeach()

# Contains #include "include "example_impl.h" for the implementation header files.
set(IMPL_INCLUDES_STRING "")
foreach(impl_header_file ${plugin_impl_header_files})
    set(IMPL_INCLUDES_STRING "${IMPL_INCLUDES_STRING}#include \"${impl_header_file}\"\n")
endforeach()

# Contains the forward declarations such as `class ExampleImpl;`.
set(FORWARD_DECLARATION_STRING "")

# Contains the constructor entries.
set(PLUGIN_CTOR_STRING "")

# Contains the destructor entries.
set(PLUGIN_DTOR_STRING "")

# Contains the member variables for the plugin instances.
set(PLUGIN_MEMBER_STRING "")

# Contains the getter methods which allow to access a plugin with device().example().
set(PLUGIN_GET_STRING "")

# Creates a list of the plugin implementations to call init()/deinit() on them.
set(PLUGIN_LIST_APPEND_STRING "")

# Go through all the plugins and generate the strings.
foreach(class_name ${plugin_class_names})

    string(TOLOWER ${class_name} class_name_lowercase)

    set(get_name ${class_name_lowercase})
    set(member_name "_${class_name_lowercase}")
    set(impl_class_name "${class_name}Impl")
    set(impl_member_name "_${class_name_lowercase}_impl")

    set(FORWARD_DECLARATION_STRING
        "${FORWARD_DECLARATION_STRING}class ${impl_class_name};\n")

    set(PLUGIN_GET_STRING
        "${PLUGIN_GET_STRING}    ${class_name} &${get_name}() { return ${member_name}; }\n")

    set(PLUGIN_MEMBER_STRING
        "${PLUGIN_MEMBER_STRING}    ${impl_class_name} *${impl_member_name};\n")
    set(PLUGIN_MEMBER_STRING
        "${PLUGIN_MEMBER_STRING}    ${class_name} ${member_name};\n")

    set(PLUGIN_CTOR_STRING
        "${PLUGIN_CTOR_STRING}    ${impl_member_name}(new ${impl_class_name}()),\n")
    set(PLUGIN_CTOR_STRING
        "${PLUGIN_CTOR_STRING}    ${member_name}(${impl_member_name}),\n")

    set(PLUGIN_DTOR_STRING
        "${PLUGIN_DTOR_STRING}    delete ${impl_member_name};\n")

    set(PLUGIN_LIST_APPEND_STRING
        "${PLUGIN_LIST_APPEND_STRING}   _plugin_impl_list.push_back(${impl_member_name});\n")

endforeach()

# Do the string replacements.
configure_file(include/device_plugin_container.h.in include/device_plugin_container.h)
configure_file(src/device_plugin_container.cpp.in src/device_plugin_container.cpp)
