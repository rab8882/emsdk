BUILD_FILE_CONTENT_TEMPLATE = """
package(default_visibility = ['//visibility:public'])
exports_files(['emscripten_config'])
"""

def get_root_and_binext(repository_ctx):
    """
    Retrieve the path to the Emscripten binary directory

    This function determines the correct Emscripten binary directory path by
    examining the operating system and architecture of the environment. It 
    supports Linux, macOS, and Windows operating systems with specific
    architectures.

    Args:
      repository_ctx: The repository context object which provides information
        about the OS and architecture, and methods to obtain paths and labels.

    Returns:
      str: The directory path to the Emscripten binaries for the detected OS
      and architecture.

    """
    if repository_ctx.os.name.startswith('linux'):
        if 'amd64' in repository_ctx.os.arch or 'x86_64' in repository_ctx.os.arch:
            return (repository_ctx.path(Label("@emscripten_bin_linux//:BUILD.bazel")).dirname, '')
        elif 'aarch64' in repository_ctx.os.arch:
            return (repository_ctx.path(Label("@emscripten_bin_linux_arm64//:BUILD.bazel")).dirname, '')
        else:
            fail('Unsupported architecture for Linux')
    elif repository_ctx.os.name.startswith('mac'):
        if 'amd64' in repository_ctx.os.arch or 'x86_64' in repository_ctx.os.arch:
            return (repository_ctx.path(Label("@emscripten_bin_mac//:BUILD.bazel")).dirname, '')
        elif 'aarch64' in repository_ctx.os.arch:
            return (repository_ctx.path(Label("@emscripten_bin_mac_arm64//:BUILD.bazel")).dirname, '')
        else:
            fail('Unsupported architecture for MacOS')
    elif repository_ctx.os.name.startswith('windows'):
        return (repository_ctx.path(Label("@emscripten_bin_win//:BUILD.bazel")).dirname, '.exe')
    else:
        fail('Unsupported operating system')

def _emscripten_cache_impl(repository_ctx):
    # Read the default emscripten configuration file
    default_config = repository_ctx.read(
        repository_ctx.path(
            Label("@emsdk//emscripten_toolchain:default_config")
        )
    )

    if repository_ctx.attr.libraries or repository_ctx.attr.flags:
        root, binext = get_root_and_binext(repository_ctx)
        llvm_root = root.get_child("bin")
        emscripten_root = root.get_child("emscripten")
        embuilder_path = emscripten_root.get_child("embuilder")
        cache_path = repository_ctx.path('cache')
        nodejs = repository_ctx.path(Label("@nodejs//:BUILD.bazel")).dirname.get_child("bin").get_child("node")
        # Create configuration file
        embuilder_config_content  = "NODE_JS = '{}{}'\n".format(nodejs, binext)
        embuilder_config_content += "LLVM_ROOT = '{}'\n".format(llvm_root)
        embuilder_config_content += "BINARYEN_ROOT = '{}'\n".format(root)
        embuilder_config_content += "EMSCRIPTEN_ROOT = '{}'\n".format(emscripten_root)
        embuilder_config_content += "CACHE = '{}'\n".format(cache_path)
        repository_ctx.file("embuilder_config", embuilder_config_content)
        embuilder_config_path = repository_ctx.path("embuilder_config")
        # Prepare the command line
        if repository_ctx.attr.libraries:
            libraries = repository_ctx.attr.libraries
        else:
            # if no libraries are requested, build everything
            libraries = ["ALL"]
        flags = ["--em-config", embuilder_config_path] + repository_ctx.attr.flags
        embuilder_args = [embuilder_path] + flags + ["build"] + libraries
        # Run embuilder
        repository_ctx.report_progress("Building secondary cache")
        result = repository_ctx.execute(embuilder_args, quiet=False)
        if result.return_code != 0:
            fail("Embuilder exited with a non-zero return code")
        # Override Emscripten's cache with the secondary cache
        default_config += "CACHE = '{}'\n".format(cache_path)

    # Create the configuration file for the toolchain and export
    repository_ctx.file('emscripten_config', default_config)
    repository_ctx.file('BUILD.bazel', BUILD_FILE_CONTENT_TEMPLATE)

_emscripten_cache = repository_rule(
    implementation = _emscripten_cache_impl,
    attrs = {
        "flags": attr.string_list(),
        "libraries": attr.string_list(),
    },
    local = True
)

def emscripten_cache(flags = [], libraries = []):
    _emscripten_cache(
        name = "emscripten_cache",
        flags = flags,
        libraries = libraries,
    )
