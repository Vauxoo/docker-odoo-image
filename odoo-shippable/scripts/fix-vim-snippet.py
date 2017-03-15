# -*- coding: utf-8 -*-

import os
import glob
import argparse
import linecache


class FixVimSnippet(object):

    def __init__(self, extensions):
        self.extensions = extensions
        self.bundle_dir = os.path.join(os.environ.get('HOME'), '.vim',
                                       'bundle')
        self.snippet = {}
        self.extension_snippet = {}
        self.repeated_snippet = {}
        self._fix()

    def _add_extension_snippet(self, extension, name_snippet, data):
        self.extension_snippet[extension].setdefault(name_snippet, [])
        for snippet in self.extension_snippet[extension][name_snippet]:
            if (data['path'] == snippet['path'] and
                    data['name_snippet'] == snippet['name_snippet']):
                return
        self.extension_snippet[extension][name_snippet].append(data)

    def _fix(self):
        if not os.path.isdir(self.bundle_dir):
            return
        module = None
        for path in glob.glob(self.bundle_dir + '/*/*/*.snippets'):
            module, folder, file_name = (os.path.relpath(
                    path, self.bundle_dir).split(os.sep))
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
                line = 0
                name_snippet = None
                begin_line = None
                end_line = None
                for line_file in open(path):
                    line_file = line_file.strip()
                    line += 1
                    if line_file.startswith('snippet'):
                        try:
                            line_split = line_file.split(" ")
                            name_snippet = line_split[1]
                            if (not all(item not in ('<', '>', '<=', '>=',
                                                     '==') for item in
                                        line_split[2:])):
                                continue
                        except Exception:
                            continue
                        begin_line = line
                        end_line = None
                    elif line_file.startswith('endsnippet'):
                        end_line = line
                    else:
                        if (linecache.getline(path, line + 1).
                                startswith('snippet')):
                            end_line = line
                    if name_snippet and end_line and begin_line:
                        data = {'path': path,
                                'name_snippet': name_snippet,
                                'begin_line': begin_line,
                                'end_line': end_line}
                        self._add_extension_snippet(extension, name_snippet,
                                                    data)
                        name_snippet = None
                        begin_line = None
                        end_line = None
                if name_snippet and begin_line and not end_line:
                    data = {'path': path,
                            'name_snippet': name_snippet,
                            'begin_line': begin_line,
                            'end_line': line}
                    self._add_extension_snippet(extension, name_snippet, data)
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
