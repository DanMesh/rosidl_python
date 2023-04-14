set(_output_path
  "${CMAKE_CURRENT_BINARY_DIR}/rosidl_generator_py/${PROJECT_NAME}")
set(_generated_extension_files "")
set(_generated_py_files "")
set(_generated_c_files "")

foreach(_typesupport_impl ${_typesupport_impls})
  set(_generated_extension_${_typesupport_impl}_files "")
endforeach()

foreach(_abs_idl_file ${rosidl_generate_interfaces_ABS_IDL_FILES})
  get_filename_component(_parent_folder "${_abs_idl_file}" DIRECTORY)
  get_filename_component(_parent_folder "${_parent_folder}" NAME)
  get_filename_component(_idl_name "${_abs_idl_file}" NAME_WE)
  string_camel_case_to_lower_case_underscore("${_idl_name}" _module_name)
  list(APPEND _generated_py_files
    "${_output_path}/${_parent_folder}/_${_module_name}.py")
  list(APPEND _generated_c_files
    "${_output_path}/${_parent_folder}/_${_module_name}_s.c")
endforeach()

file(MAKE_DIRECTORY "${_output_path}")
file(WRITE "${_output_path}/__init__.py" "")

# collect relative paths of directories containing to-be-installed Python modules
# add __init__.py files where necessary
set(_generated_py_dirs "")
foreach(_generated_py_file ${_generated_py_files})
  get_filename_component(_parent_folder "${_generated_py_file}" DIRECTORY)
  set(_init_module "${_parent_folder}/__init__.py")
  list(FIND _generated_py_files "${_init_module}" _index)
  if(_index EQUAL -1)
    list(APPEND _generated_py_files "${_init_module}")

    string(LENGTH "${_output_path}" _length)
    math(EXPR _index "${_length} + 1")
    string(SUBSTRING "${_parent_folder}" ${_index} -1 _relative_directory)
    list(APPEND _generated_py_dirs "${_relative_directory}")
  endif()
endforeach()

if(NOT _generated_c_files STREQUAL "")
    foreach(_typesupport_impl ${_typesupport_impls})
      list(APPEND _generated_extension_${_typesupport_impl}_files "${_output_path}/_${PROJECT_NAME}_s.ep.${_typesupport_impl}.c")
      list(APPEND _generated_extension_files "${_generated_extension_${_typesupport_impl}_files}")
    endforeach()
endif()
set(_dependency_files "")
set(_dependencies "")
foreach(_pkg_name ${rosidl_generate_interfaces_DEPENDENCY_PACKAGE_NAMES})
  foreach(_idl_file ${${_pkg_name}_IDL_FILES})
    set(_abs_idl_file "${${_pkg_name}_DIR}/../${_idl_file}")
    normalize_path(_abs_idl_file "${_abs_idl_file}")
    list(APPEND _dependency_files "${_abs_idl_file}")
    list(APPEND _dependencies "${_pkg_name}:${_abs_idl_file}")
  endforeach()
endforeach()

set(target_dependencies
  "${rosidl_generator_py_BIN}"
  ${rosidl_generator_py_GENERATOR_FILES}
  "${rosidl_generator_py_TEMPLATE_DIR}/_action_pkg_typesupport_entry_point.c.em"
  "${rosidl_generator_py_TEMPLATE_DIR}/_action.py.em"
  "${rosidl_generator_py_TEMPLATE_DIR}/_idl_pkg_typesupport_entry_point.c.em"
  "${rosidl_generator_py_TEMPLATE_DIR}/_idl_support.c.em"
  "${rosidl_generator_py_TEMPLATE_DIR}/_idl.py.em"
  "${rosidl_generator_py_TEMPLATE_DIR}/_msg_pkg_typesupport_entry_point.c.em"
  "${rosidl_generator_py_TEMPLATE_DIR}/_msg_support.c.em"
  "${rosidl_generator_py_TEMPLATE_DIR}/_msg.py.em"
  "${rosidl_generator_py_TEMPLATE_DIR}/_srv_pkg_typesupport_entry_point.c.em"
  "${rosidl_generator_py_TEMPLATE_DIR}/_srv.py.em"
  ${rosidl_generate_interfaces_ABS_IDL_FILES}
  ${_dependency_files})
foreach(dep ${target_dependencies})
  if(NOT EXISTS "${dep}")
    message(FATAL_ERROR "Target dependency '${dep}' does not exist")
  endif()
endforeach()

set(generator_arguments_file "${CMAKE_CURRENT_BINARY_DIR}/rosidl_generator_py__arguments.json")
rosidl_write_generator_arguments(
  "${generator_arguments_file}"
  PACKAGE_NAME "${PROJECT_NAME}"
  IDL_TUPLES "${rosidl_generate_interfaces_IDL_TUPLES}"
  ROS_INTERFACE_DEPENDENCIES "${_dependencies}"
  OUTPUT_DIR "${_output_path}"
  TEMPLATE_DIR "${rosidl_generator_py_TEMPLATE_DIR}"
  GENERATOR_FILES "${rosidl_generator_py_GENERATOR_FILES}"
  TARGET_DEPENDENCIES ${target_dependencies}
)

list(APPEND rosidl_generator_arguments_files ${generator_arguments_file})
