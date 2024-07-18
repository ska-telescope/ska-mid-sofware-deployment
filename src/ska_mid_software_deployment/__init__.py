"""This package is used to extract the ska-mid-software-deployment version."""

from os import path


def getversion():
    """Get server version based on `.release` file value.

    Returns:
        str: value of the release in server notation
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
