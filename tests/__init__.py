"""
This package provides tango integration of a Sky Simulator Controller.

It is used in the SKA test equipment hardware.
"""

from os import path


def getversion():
    """Get semver version based on `.release` file value.

    :return: the value of the release in semver notation
    """
    file_name = ".release"
    basepath = path.dirname(__file__)
    filepath = path.abspath(path.join(basepath, "..", "..", file_name))

    with open(filepath, encoding="utf8") as in_f:
        release_line = in_f.readline().strip("\n").split("=")
        release = release_line[-1]

    return release


__version__ = getversion()

if __name__ == "__main__":
    print(__version__)
