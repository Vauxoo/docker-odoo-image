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
                if self.extensions and not name in self.extensions:
                    continue
                if not self.snippet.has_key(name):
                    self.snippet[name] = []
                self.snippet[name].append({'snippet': file_name,
                                           'module': module,
                                           'folder': folder,
                                           'path': path})
            for extension, snippets in self.snippet.iteritems():
                if len(snippets) > 1:
                    for snippet in snippets:
                        if not self.extension_snippet.has_key(extension):
                            self.extension_snippet[extension] = {}
                        path = snippet['path']
                        with open(path) as _file:
                            _snippets = [item.strip() for item in
                                         _file.readlines()]
                            line = 0
                            total_lines = len(_snippets)
                            name_snippet = None
                            begin_line = None
                            end_line = None
                            for _snippet in _snippets:
                                line += 1
                                if _snippet.startswith('snippet'):
                                    try:
                                        name_snippet = _snippet.split(" ")[1]
                                    except Exception:
                                        continue
                                    begin_line = line
                                    end_line = None
                                elif _snippet.startswith('endsnippet'):
                                    end_line = line
                                else:
                                    _next = _snippets[(line - 1) +
                                                      (0 if (line + 1) >=
                                                       total_lines else 1)]
                                    if (_next.startswith('snippet') or
                                            (line == total_lines)):
                                        end_line = line
                                if name_snippet and end_line and begin_line:
                                    if (not self.extension_snippet[extension]
                                            .has_key(name_snippet)):
                                        self.extension_snippet[extension]\
                                            [name_snippet] = []
                                    self.extension_snippet[extension]\
                                        [name_snippet].append({
                                            'path': path,
                                            'name_snippet': name_snippet,
                                            'begin_line': begin_line,
                                            'end_line': end_line
                                    })
                                    name_snippet = None
                                    begin_line = None
                                    end_line = None
            for extension in self.extension_snippet:
                for snippet in self.extension_snippet[extension]:
                    if len(self.extension_snippet[extension][snippet]) > 1:
                        original = self.extension_snippet[extension]\
                            [snippet][0]
                        print "Snippet repeated for '%s' named '%s'" % (
                            extension, snippet)
                        print "First defined in %s line(%s:%s)" % (
                            original['path'], original['begin_line'],
                            original['end_line'])
                        print "+++++"
                        repeated = self.extension_snippet[extension][snippet][1:]
                        for _snippet in repeated:
                            print "Snippet defined in %s line(%s:%s)" %(
                                _snippet['path'], _snippet['begin_line'],
                                 _snippet['end_line'])
                        print "+++++"


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--extensions', dest='extensions', default=[],
                        help='Extensions you will be looking for')
    FixVimSnippet(parser.parse_args().extensions)
