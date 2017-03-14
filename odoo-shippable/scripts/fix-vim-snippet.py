# -*- coding: utf-8 -*-

import os
import glob
import argparse


class FixVimSnippet(object):

    def __init__(self, extensions):
        self.extensions = extensions
        self.bundle_dir = os.path.join(os.environ.get('HOME'), '.vim',
                                       'bundle')
        self.snippet = {}
        self.extension_snippet = {}
        self.repeated_snippet = {}
        self._fix()

    def _fix(self):
        if os.path.isdir(self.bundle_dir):
            module = None
            for path in glob.glob(self.bundle_dir + '/*/*/*.snippets'):
                module, folder, file_name = (path.replace(
                    self.bundle_dir + os.sep, '').split(os.sep))
                name, extension = os.path.splitext(file_name)
                if self.extensions and name not in self.extensions:
                    continue
                self.snippet.setdefault(name, []).append({'snippet': file_name,
                                                          'module': module,
                                                          'folder': folder,
                                                          'path': path})
            for extension, snippets in self.snippet.items():
                if len(snippets) == 1:
                    continue
                self.extension_snippet.setdefault(extension, {})
                for snippet in snippets:
                    path = snippet['path']
                    with open(path) as fobj:
                        lines_file = [item.strip() for item in
                                      fobj.readlines()]
                        line = 0
                        total_lines = len(lines_file)
                        name_snippet = None
                        begin_line = None
                        end_line = None
                        for line_file in lines_file:
                            line += 1
                            if line_file.startswith('snippet'):
                                try:
                                    name_snippet = line_file.split(" ")[1]
                                except Exception:
                                    continue
                                begin_line = line
                                end_line = None
                            elif line_file.startswith('endsnippet'):
                                end_line = line
                            else:
                                next = lines_file[(line - 1) +
                                                  (0 if (line + 1) >=
                                                   total_lines else 1)]
                                if (next.startswith('snippet') or
                                        (line == total_lines)):
                                    end_line = line
                            if name_snippet and end_line and begin_line:
                                self.extension_snippet[extension].setdefault(
                                    name_snippet, [])
                                self.extension_snippet[extension] \
                                    [name_snippet].append({
                                        'path': path,
                                        'name_snippet': name_snippet,
                                        'begin_line': begin_line,
                                        'end_line': end_line,
                                })
                                name_snippet = None
                                begin_line = None
                                end_line = None
            for extension, snippets in self.extension_snippet.items():
                for name, snippet in snippets.items():
                    if len(snippet) == 1:
                        continue
                    original = snippet[0]
                    print "Snippet repeated for '%s' named '%s'" % (extension,
                                                                    name)
                    print "First defined in %s line(%s:%s)" % (
                        original['path'], original['begin_line'],
                        original['end_line'])
                    print "+++++"
                    duplicates = snippet[1:]
                    for duplicate in duplicates:
                        print "Snippet defined in %s line(%s:%s)" %(
                            duplicate['path'], duplicate['begin_line'],
                            duplicate['end_line'])
                    print "+++++"


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--extensions', dest='extensions', default=[],
                        help='Extensions you will be looking for')
    FixVimSnippet(parser.parse_args().extensions)
