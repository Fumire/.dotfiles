import os.path
import subprocess
import ycm_core

DIR_OF_THIS_SCRIPT = os.path.abspath(os.path.dirname(__file__))
DIR_OF_THIRD_PARTY = os.path.join(DIR_OF_THIS_SCRIPT, 'third_party')

flags = ["-Wall", "-Wextra", "-Werror", "-std=c++14", "-x", "c++", "-isystem", "/System/Library/Frameworks/Python.framework/Headers", "-isystem", "/usr/local/include", "-isystem", "/usr/local/include/eigen3", "-I", "/usr/include", "-I", "."]

SOURCE_EXTENSIONS = [".cpp", ".cxx", ".cc", "c"]

compilation_database_folder = ''

if compilation_database_folder:
    database = ycm_core.CompilationDatabse(compilation_database_folder)
else:
    database = None


def MakeRelativePathsInFlagsAbsolute(flags, working_directory):
    if not working_directory:
        return list(flags)
    new_flags = []
    make_next_absolute = False
    path_flags = ['-isystem', '-I', '-iquote', '--sysroot=']
    for flag in flags:
        new_flag = flag

        if make_next_absolute:
            make_next_absolute = False
            if not flag.startswith('/'):
                new_flag = os.path.join(working_directory, flag)

        for path_flag in path_flags:
            if flag == path_flag:
                make_next_absolute = True
                break

            if flag.startswith(path_flag):
                path = flag[len(path_flag):]
                new_flag = path_flag + os.path.join(working_directory, path)
                break

        if new_flag:
            new_flags.append(new_flag)
    return new_flags


def DirectoryOfThisScript():
    return os.path.dirname(os.path.abspath(__file__))


def GetStandardLibraryIndexInSysPath(sys_path):
    for index, path in enumerate(sys_path):
        if os.path.isfile(os.path.join(path, 'os.py')):
            return index
    raise RuntimeError('Could not find standard library path in Python path.')


def PythonSysPath(**kwargs):
    sys_path = kwargs['sys_path']

    dependencies = [os.path.join(DIR_OF_THIS_SCRIPT, 'python'), os.path.join(DIR_OF_THIRD_PARTY, 'requests-futures'), os.path.join(DIR_OF_THIRD_PARTY, 'ycmd'), os.path.join(DIR_OF_THIRD_PARTY, 'requests_deps', 'idna'), os.path.join(DIR_OF_THIRD_PARTY, 'requests_deps', 'chardet'), os.path.join(DIR_OF_THIRD_PARTY, 'requests_deps', 'urllib3', 'src'), os.path.join(DIR_OF_THIRD_PARTY, 'requests_deps', 'certifi'), os.path.join(DIR_OF_THIRD_PARTY, 'requests_deps', 'requests')]

    # The concurrent.futures module is part of the standard library on Python 3.
    interpreter_path = kwargs['interpreter_path']
    major_version = int(subprocess.check_output([interpreter_path, '-c', 'import sys; print( sys.version_info[ 0 ] )']).rstrip().decode('utf8'))
    if major_version == 2:
        dependencies.append(os.path.join(DIR_OF_THIRD_PARTY, 'pythonfutures'))

    sys_path[0:0] = dependencies
    sys_path.insert(GetStandardLibraryIndexInSysPath(sys_path) + 1, os.path.join(DIR_OF_THIRD_PARTY, 'python-future', 'src'))

    return sys_path


def FlagsForFile(filename):
    if database:
        compilation_info = database.GetCompilationInfoForFile(filename)
        final_flags = MakeRelativePathsInFlagsAbsolute(compilation_info.compiler_flags_, compilation_info.compiler_working_dir_)
    else:
        relative_to = DirectoryOfThisScript()
        final_flags = MakeRelativePathsInFlagsAbsolute(flags, relative_to)

    return {'flags': final_flags, 'do_cache': True}
