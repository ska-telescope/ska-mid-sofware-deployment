"""This module tests the ska_mid_Software_deployment version."""

from os import path

import ska_mid_software_deployment


def get_version():
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


def test_version() -> None:
    """Test that the ska_ser_test_equipment version is as expected."""
    assert ska_mid_software_deployment.__version__ == get_version()
