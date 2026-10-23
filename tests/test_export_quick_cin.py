#!/usr/bin/env python3
"""export_quick_cin.py: static OpenVanilla-style .cin from kinfx_quick.dict.yaml."""
from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "scripts"))

import export_quick_cin as exp

DICT = ROOT / "schemas/kinfx-quick/kinfx_quick.dict.yaml"

# OpenVanilla DataTables/simplex.cin `%keyname` (a 日 … z 重).
SIMPLEX_KEYNAMES = """\
a 日
b 月
c 金
d 木
e 水
f 火
g 土
h 竹
i 戈
j 十
k 大
l 中
m 一
n 弓
o 人
p 心
q 手
r 口
s 尸
t 廿
u 山
v 女
w 田
x 難
y 卜
z 重
"""


def _section(text: str, begin: str, end: str) -> str:
    return text.split(begin, 1)[1].split(end, 1)[0]


def _chardef_rows(text: str) -> list[tuple[str, str]]:
    body = _section(text, "%chardef begin\n", "%chardef end")
    rows = []
    for line in body.splitlines():
        if not line or line.startswith("#"):
            continue
        code, ch = line.split(" ", 1)
        rows.append((ch, code))
    return rows


def _by_code(rows: list[tuple[str, str]]) -> dict[str, list[str]]:
    out: dict[str, list[str]] = {}
    for ch, code in rows:
        out.setdefault(code, []).append(ch)
    return out


class KeynameTest(unittest.TestCase):
    def test_matches_openvanilla_simplex_radicals(self) -> None:
        self.assertEqual("\n".join(exp.keyname_lines()) + "\n", SIMPLEX_KEYNAMES)


class ParseDictTest(unittest.TestCase):
    def test_reads_text_code_and_keeps_order(self) -> None:
        version, rows = exp.parse_quick_dict(
            '---\nname: kinfx_quick\nversion: "9.9.9"\n...\n'
            "日\ta\t1\n"
            "曰\ta\t2\n"
            "好\tvd\t3\n"
        )
        self.assertEqual(version, "9.9.9")
        self.assertEqual(rows, [("日", "a"), ("曰", "a"), ("好", "vd")])

    def test_keeps_ideographic_space(self) -> None:
        _version, rows = exp.parse_quick_dict('---\nversion: "1"\n...\n\u3000\tza\t0\n')
        self.assertEqual(rows, [("\u3000", "za")])
        self.assertEqual(_chardef_rows(exp.render_cin(rows, "1")), [("\u3000", "za")])

    def test_rejects_bad_code_and_ascii_space_in_text(self) -> None:
        with self.assertRaises(SystemExit):
            exp.parse_quick_dict("---\nversion: \"1\"\n...\n日\tA\t1\n")
        with self.assertRaises(SystemExit):
            exp.parse_quick_dict("---\nversion: \"1\"\n...\n日 曰\ta\t1\n")
        with self.assertRaises(SystemExit):
            exp.parse_quick_dict("name: kinfx_quick\n日\ta\t1\n")


class RenderCinTest(unittest.TestCase):
    def test_headers_and_chardef_lines(self) -> None:
        text = exp.render_cin([("日", "a"), ("曰", "a"), ("好", "vd")], version="0.4.1")
        self.assertEqual(text.splitlines()[0], "%gen_inp")
        for marker in ("%gen_inp", "%keyname", "%chardef"):
            self.assertIn(marker, text)
        self.assertIn("%keyname begin\n", text)
        self.assertIn("%keyname end\n", text)
        self.assertIn("%chardef begin\n", text)
        self.assertIn("%chardef end\n", text)
        self.assertEqual(_section(text, "%keyname begin\n", "%keyname end"), SIMPLEX_KEYNAMES)
        self.assertEqual(
            _chardef_rows(text),
            [("日", "a"), ("曰", "a"), ("好", "vd")],
        )
        self.assertNotIn("\t", text)
        self.assertIn("version 0.4.1", text)
        self.assertIn("NOTICE", text)
        self.assertIn("LGPL-3.0", text)
        self.assertNotIn("Vanilla-compatible", text)
        self.assertNotIn("drop-in", text)
        self.assertIn("Mixed English/Chinese input, Lua,", text)
        self.assertIn("association words are not in this table", text)

    def test_writes_utf8_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            src = Path(tmp) / "mini.dict.yaml"
            src.write_text(
                '---\nname: kinfx_quick\nversion: "0.4.1"\n...\n日\ta\t10\n好\tvd\t9\n',
                encoding="utf-8",
            )
            out = Path(tmp) / "nested" / "kinfx_quick.cin"
            count = exp.export_cin(src, out)
            self.assertEqual(count, 2)
            written = out.read_text(encoding="utf-8")
            self.assertTrue(written.startswith("%gen_inp\n"))
            self.assertEqual(_chardef_rows(written), [("日", "a"), ("好", "vd")])


class RealDictTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.version, cls.rows = exp.load_quick_dict(DICT)
        cls.text = exp.render_cin(cls.rows, cls.version)
        cls.by_code = _by_code(_chardef_rows(cls.text))

    def test_real_table_samples(self) -> None:
        self.assertEqual(self.text.splitlines()[0], "%gen_inp")
        for marker in ("%gen_inp", "%keyname", "%chardef"):
            self.assertIn(marker, self.text)
        self.assertGreater(len(self.rows), 600)
        self.assertEqual(len(_chardef_rows(self.text)), len(self.rows))
        # schemas/kinfx-quick/kinfx_quick.dict.yaml: a is 日 then 曰; vd includes 好.
        self.assertEqual(self.by_code["a"][:2], ["日", "曰"])
        self.assertIn("好", self.by_code["vd"])
        self.assertEqual(self.by_code["vd"][0], "好")
        self.assertIn("\u3000", self.by_code["za"])
        dict_vd = [ch for ch, code in self.rows if code == "vd"]
        self.assertEqual(self.by_code["vd"], dict_vd)
        self.assertIn("NOTICE", self.text)
        self.assertIn("LGPL-3.0", self.text)
        self.assertNotIn("24037026", self.text)


if __name__ == "__main__":
    unittest.main()
