#!/usr/bin/env python3
"""Sort keys in OpenProject locale YAML files to satisfy yamllint's key-ordering.

Sorts mapping keys recursively in Unicode codepoint order (matching yamllint's
strcoll comparison under CI's C/POSIX locale for the ASCII keys these files use).
Sequences and scalar values are left untouched. Comments, quoting and block
scalars are preserved via ruamel.yaml round-trip.

Usage:
    python3 script/i18n/sort_locales.py FILE [FILE ...]
"""
from __future__ import annotations

import io
import sys
from pathlib import Path

try:
    from ruamel.yaml import YAML
    from ruamel.yaml.comments import CommentedMap, CommentedSeq
except ModuleNotFoundError:
    sys.stderr.write(
        "sort_locales.py requires ruamel.yaml. Install it with:\n"
        "  pip install -r script/i18n/requirements.txt\n"
    )
    sys.exit(1)


def make_yaml() -> YAML:
    yaml = YAML()
    yaml.preserve_quotes = True
    yaml.width = 4096
    yaml.indent(mapping=2, sequence=4, offset=2)
    return yaml


def _sort_key(key):
    """Return the YAML scalar text yamllint compares against.

    ruamel parses unquoted true/false/null as Python objects, but yamllint
    compares the literal scalar text, so map them back to what gets written.
    """
    if isinstance(key, bool):
        return "true" if key else "false"
    if key is None:
        return "null"
    return str(key)


def _bare(comment_line: str) -> str:
    """'# foo' -> 'foo', '#foo' -> 'foo', '#' -> ''. ruamel's comment APIs re-add '# '."""
    s = comment_line.lstrip()[1:]  # drop leading whitespace and the '#'
    return s[1:] if s.startswith(" ") else s


def _split_post(value: str):
    """Split a ruamel post-comment token value into (eol, [own_lines]).

    `eol` is the comment on the same line as the key's value (or None);
    `own_lines` are the own-line comments that follow it (which visually
    precede the next key). All returned text is bare (no leading '#').
    """
    segments = value.split("\n")
    eol = None
    own_lines = []
    starts_inline = not value.startswith("\n")
    for index, segment in enumerate(segments):
        stripped = segment.strip()
        if not stripped.startswith("#"):
            continue
        if index == 0 and starts_inline:
            eol = _bare(stripped)
        else:
            own_lines.append(_bare(stripped))
    return eol, own_lines


def reanchor_comments(node, child_indent: int = 0) -> None:
    """Re-attach own-line comments to the key they precede, so they travel
    with that key when keys are reordered. Run before sort_node."""
    if isinstance(node, CommentedMap):
        for key in list(node.keys()):
            reanchor_comments(node[key], child_indent + 2)

        keys = list(node.keys())

        # NOTE: we deliberately do NOT touch a mapping's leading comment
        # (node.ca.comment). For nested mappings ruamel also stores that comment
        # on the parent's `ca.items[key]`, which travels with the key on reorder;
        # moving it here would render it twice. The only unanchored leading
        # comment is the root document header, whose mapping has a single key
        # (`en`) and never reorders.

        # Each key's following own-line comments -> before the next key.
        for index, key in enumerate(keys):
            item = node.ca.items.get(key)
            if not item or item[2] is None:
                continue
            eol, own_lines = _split_post(item[2].value)
            if not own_lines or index + 1 >= len(keys):
                continue  # nothing to move, or trailing comments at mapping end
            node.ca.items[key][2] = None
            if eol is not None:
                node.yaml_add_eol_comment(eol, key)
            node.yaml_set_comment_before_after_key(
                keys[index + 1], before="\n".join(own_lines), indent=child_indent)

    elif isinstance(node, CommentedSeq):
        for item in node:
            reanchor_comments(item, child_indent + 2)


def sort_node(node) -> None:
    """Recursively sort mapping keys in place by codepoint order."""
    if isinstance(node, CommentedMap):
        for key in list(node.keys()):
            sort_node(node[key])
        for key in sorted(node.keys(), key=_sort_key):
            node.move_to_end(key)
    elif isinstance(node, CommentedSeq):
        for item in node:
            sort_node(item)


def flatten(node, prefix=()):
    """Yield (path, value) for every leaf; order-independent."""
    if isinstance(node, dict):
        for key, value in node.items():
            yield from flatten(value, prefix + (str(key),))
    elif isinstance(node, list):
        for index, value in enumerate(node):
            yield from flatten(value, prefix + (f"[{index}]",))
    else:
        yield prefix, node


def _normalize_eol_comment_spacing(text: str) -> str:
    """Ensure at least 2 spaces before end-of-line comments (yamllint's
    comments rule). Comment positions are taken from a ruamel parse, so a
    '#' inside a string value is never touched."""
    data = make_yaml().load(text)
    targets = []  # (0-based line, 0-based column of '#')

    def visit(node):
        ca = getattr(node, "ca", None)
        if ca is not None:
            for _key, item in ca.items.items():
                token = item[2] if item else None
                if token is not None and not token.value.startswith("\n"):
                    targets.append((token.start_mark.line, token.start_mark.column))
        if isinstance(node, dict):
            for value in node.values():
                visit(value)
        elif isinstance(node, list):
            for value in node:
                visit(value)

    if data is not None:
        visit(data)

    lines = text.split("\n")
    for line_no, col in targets:
        if line_no >= len(lines):
            continue
        line = lines[line_no]
        if col < 1 or col > len(line) or line[col] != "#":
            continue
        start = col
        while start > 0 and line[start - 1] == " ":
            start -= 1
        # only an end-of-line comment (content precedes the spaces), under-spaced
        if start > 0 and (col - start) < 2:
            lines[line_no] = line[:start] + "  " + line[col:]
    return "\n".join(lines)


def sort_file(path: str) -> None:
    yaml = make_yaml()
    text = Path(path).read_text()

    # Preserve everything up to the root `en:` line verbatim: the license
    # header and any `---` document-start marker. ruamel does not reliably
    # round-trip pre-document leading comments, so we never hand them to it.
    lines = text.splitlines(keepends=True)
    body_start = next(
        (i for i, line in enumerate(lines) if line.rstrip("\n") == "en:"), None)
    if body_start is None:
        return  # no recognizable root mapping; leave untouched
    preamble = "".join(lines[:body_start])
    body = "".join(lines[body_start:])

    data = yaml.load(body)
    if data is None:
        return

    before = dict(flatten(data))
    reanchor_comments(data)
    sort_node(data)
    after = dict(flatten(data))
    if before != after:
        raise SystemExit(
            f"{path}: refusing to write — sorting changed content, not just order"
        )

    buffer = io.StringIO()
    yaml.dump(data, buffer)
    body_out = _normalize_eol_comment_spacing(buffer.getvalue())
    body_out = body_out.rstrip("\n") + "\n"  # exactly one trailing newline
    Path(path).write_text(preamble + body_out)


def main(argv: list[str]) -> int:
    for path in argv[1:]:
        sort_file(path)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
