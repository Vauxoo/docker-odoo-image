# coding: utf-8
"""Check if any file has changed and then build this Dockerfile"""

import os
import sys
import subprocess
import argparse


class DockerOdooImages(object):
    """Class to build if has changed any file"""

    def __init__(self, folder, docker_image):
        """Init method
        folder : Folder to containt the Dockerfile
        docker_image : Docker image to build
        """
        self._folder = folder
        self._relpath = os.path.relpath(self._folder)
        self._docker_file_path = os.path.join(self._folder, 'Dockerfile')
        self._docker_image = docker_image
        self._path = os.getcwd()

    def check_path(self):
        """Check if Docker file is present and the format"""
        if (not os.path.isdir(self._folder) or
                not os.path.isfile(self._docker_file_path)):
            raise Exception('No Dockerfile', 'The folder %s not containt'
                            ' Dockerfile' % self._folder, ' or not exist')
        cmd = ['dockerlint', os.path.join(self._relpath, 'Dockerfile')]
        try:
            print subprocess.check_output(cmd)
        except subprocess.CalledProcessError:
            raise Exception('Dockerfile file is bad formatted')
        return True

    def build(self):
        """Build changed image"""
        cmd = ['git', 'remote', '-v']
        print " ".join(cmd)
        print subprocess.check_output(cmd)
        cmd = ['git', 'branch', '-a']
        print " ".join(cmd)
        print subprocess.check_output(cmd)
        can_be_build = self.check_path()
        cmd = ['git', 'diff', 'HEAD^', 'HEAD', '--name-only',
               '--relative=%s' % self._relpath]
        print " ".join(cmd)
        diffs = subprocess.check_output(cmd)
        if isinstance(diffs, basestring):
            differences = [diff for diff in diffs.split('\n') if diff != '']
            if not differences:
                can_be_build = False
        if can_be_build:
            is_travis = os.environ.get("TRAVIS", "false")
            cmd = ["docker", "build",
                   "--build-arg", "IS_TRAVIS=%s" % is_travis,
                   "--rm", "-t", self._docker_image, self._folder]
            print " ".join(cmd)
            return subprocess.call(cmd)
        return 0


if __name__ == "__main__":
    argument_parser = argparse.ArgumentParser()
    argument_parser.add_argument('-f', '--folder', help='Folder to containt'
                                 'the Dockerfile', dest='folder',
                                 required=True)
    argument_parser.add_argument('-di', '--docker-image', help='Docker image'
                                 'to build', dest='docker_image',
                                 required=True)
    arguments = argument_parser.parse_args()
    docker_odoo_images = DockerOdooImages(arguments.folder,
                                          arguments.docker_image)
    sys.exit(docker_odoo_images.build())
