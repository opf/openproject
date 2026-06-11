import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import sort_locales  # noqa: E402


def run_sort(tmp_path, text):
    f = tmp_path / "en.yml"
    f.write_text(text)
    sort_locales.sort_file(str(f))
    return f.read_text()


def test_sorts_top_level_and_nested_keys(tmp_path):
    out = run_sort(tmp_path, (
        "en:\n"
        "  banana: \"B\"\n"
        "  apple:\n"
        "    zebra: 2\n"
        "    aardvark: 1\n"
    ))
    assert out.index("apple:") < out.index("banana:")
    assert out.index("aardvark:") < out.index("zebra:")


def test_own_line_comment_before_non_first_key_moves_with_it(tmp_path):
    out = run_sort(tmp_path, (
        "en:\n"
        "  zebra: 1\n"
        "  # note about alpha\n"
        "  alpha: 2\n"
    ))
    assert out.index("alpha:") < out.index("zebra:")
    # the comment travels with alpha and stays directly above it
    assert "# note about alpha\n  alpha:" in out


def test_leading_comment_before_first_key_stays_at_block_top(tmp_path):
    # Documented behavior: a comment before the FIRST key of a mapping is
    # treated as a block header and stays at the top after sorting, rather
    # than following its original first key. (Dedent/first-key comments are
    # not auto-relocated; they're hand-fixed during the one-time sort.)
    out = run_sort(tmp_path, (
        "en:\n"
        "  # block header\n"
        "  beta: 2\n"
        "  alpha: 1\n"
    ))
    assert out.index("alpha:") < out.index("beta:")
    assert out.index("# block header") < out.index("alpha:")


def test_sorts_quoted_keys_by_unquoted_value(tmp_path):
    out = run_sort(tmp_path, (
        "en:\n"
        "  \"zzz\": 1\n"
        "  \"import/jira\": 2\n"
        "  aaa: 3\n"
    ))
    # codepoint order: aaa (97) < import/jira (105) < zzz (122)
    assert out.index("aaa:") < out.index("import/jira") < out.index("zzz")
    assert '"import/jira"' in out  # original quoting preserved


def test_preserves_block_scalars(tmp_path):
    out = run_sort(tmp_path, (
        "en:\n"
        "  zebra: \"Z\"\n"
        "  alpha: |\n"
        "    multi\n"
        "    line\n"
    ))
    assert out.index("alpha:") < out.index("zebra:")
    assert "|" in out
    assert "    multi\n    line" in out


def test_multiline_comment_block_moves_with_following_key(tmp_path):
    out = run_sort(tmp_path, (
        "en:\n"
        "  zebra: 1\n"
        "  # explains alpha line 1\n"
        "  # explains alpha line 2\n"
        "  alpha: 2\n"
    ))
    # the whole block stays directly above alpha, which sorts first
    assert "# explains alpha line 1\n  # explains alpha line 2\n  alpha:" in out
    assert out.index("alpha:") < out.index("zebra:")


def test_eol_comment_stays_with_its_key_and_own_line_moves(tmp_path):
    out = run_sort(tmp_path, (
        "en:\n"
        "  zebra: 1  # eol on zebra\n"
        "  # describes alpha\n"
        "  alpha: 2\n"
    ))
    # eol comment remains on zebra's line; own-line comment moves above alpha
    assert "zebra: 1  # eol on zebra" in out
    assert "# describes alpha\n  alpha:" in out
    assert out.index("alpha:") < out.index("zebra:")


import pytest  # noqa: E402
from ruamel.yaml import YAML  # noqa: E402


def _load(text):
    return YAML().load(text)


def test_preserves_all_key_paths_and_values(tmp_path):
    src = (
        "en:\n"
        "  user:\n"
        "    display_format: \"Display format\"\n"
        "    deletion: \"Deletion\"\n"
        "  activities:\n"
        "    index:\n"
        "      title: \"T\"\n"
    )
    out = run_sort(tmp_path, src)
    before = dict(sort_locales.flatten(_load(src)))
    after = dict(sort_locales.flatten(_load(out)))
    assert before == after  # same key-paths and values, order aside


def test_duplicate_keys_raise(tmp_path):
    with pytest.raises(Exception):
        run_sort(tmp_path, (
            "en:\n"
            "  alpha: 1\n"
            "  alpha: 2\n"
        ))


def _assert_keys_sorted(node):
    if isinstance(node, dict):
        keys = [sort_locales._sort_key(k) for k in node.keys()]
        assert keys == sorted(keys), f"unsorted mapping: {keys}"
        for value in node.values():
            _assert_keys_sorted(value)
    elif isinstance(node, list):
        for value in node:
            _assert_keys_sorted(value)


def test_output_is_yamllint_ordered(tmp_path):
    out = run_sort(tmp_path, (
        "en:\n"
        "  gamma: 3\n"
        "  alpha:\n"
        "    delta: 1\n"
        "    beta: 2\n"
        "  bool_keys:\n"
        "    true: t\n"
        "    false: f\n"
    ))
    _assert_keys_sorted(_load(out))
    # boolean keys sort as written: false before true
    assert out.index("false:") < out.index("true:")


def test_preserves_license_header_and_document_marker(tmp_path):
    header = (
        "#-- copyright\n"
        "# OpenProject is an open source project management software.\n"
        "#++\n"
        "\n"
        "---\n"
    )
    out = run_sort(tmp_path, header + (
        "en:\n"
        "  zebra: 1\n"
        "  alpha: 2\n"
    ))
    # header + marker preserved verbatim and still at the very top
    assert out.startswith(header)
    assert out.index("alpha:") < out.index("zebra:")


def test_single_trailing_newline(tmp_path):
    out = run_sort(tmp_path, "en:\n  b: 1\n  a: 2\n\n\n")
    assert out.endswith("\n")
    assert not out.endswith("\n\n")


def test_normalizes_eol_comment_spacing(tmp_path):
    out = run_sort(tmp_path, (
        "en:\n"
        "  zebra: \"Z\" # one space before comment\n"
        "  alpha: \"a # b is not a comment\"\n"
    ))
    # the real eol comment gets two spaces; the '#' inside the string is untouched
    assert '"Z"  # one space before comment' in out
    assert '"a # b is not a comment"' in out
    assert out.index("alpha:") < out.index("zebra:")


def test_idempotent(tmp_path):
    src = (
        "en:\n"
        "  gamma: 3\n"
        "  # note for alpha\n"
        "  alpha: 1\n"
        "  beta: 2\n"
    )
    once = run_sort(tmp_path, src)
    twice = run_sort(tmp_path, once)
    assert once == twice
