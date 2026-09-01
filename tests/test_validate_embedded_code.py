#!/usr/bin/env python3
"""Security tests for fail-closed embedded-code tool requirements."""

from __future__ import annotations

import contextlib
import importlib.util
import io
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "validate-embedded-code.py"


def load_validator():
    spec = importlib.util.spec_from_file_location("validate_embedded_code", SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError("Unable to load embedded-code validator.")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class EmbeddedCodeValidatorTests(unittest.TestCase):
    def run_without_tool(self, language: str) -> tuple[int, str]:
        module = load_validator()
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "example.md").write_text(
                f"```{language}\n---\n- name: example\n  debug:\n    msg: ok\n```\n",
                encoding="utf-8",
            )
            module.ROOT = root
            stderr = io.StringIO()
            with (
                mock.patch.object(sys, "argv", [str(SCRIPT), "example.md"]),
                mock.patch.object(module.shutil, "which", return_value=None),
                contextlib.redirect_stderr(stderr),
            ):
                result = module.main()
        return result, stderr.getvalue()

    def test_ansible_fence_requires_ansible_lint(self) -> None:
        result, stderr = self.run_without_tool("ansible")
        self.assertEqual(result, 1)
        self.assertIn("ansible-lint is required", stderr)

    def test_shell_fence_requires_shellcheck(self) -> None:
        result, stderr = self.run_without_tool("bash")
        self.assertEqual(result, 1)
        self.assertIn("ShellCheck is required", stderr)


if __name__ == "__main__":
    unittest.main()
