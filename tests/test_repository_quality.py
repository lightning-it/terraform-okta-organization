#!/usr/bin/env python3
"""Security tests for fail-closed repository-quality tool execution."""

from __future__ import annotations

import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "lit-repository-quality.py"


def load_repository_quality():
    spec = importlib.util.spec_from_file_location("lit_repository_quality", SCRIPT)
    if spec is None or spec.loader is None:
        raise RuntimeError("Unable to load repository-quality validator.")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class RepositoryQualityTests(unittest.TestCase):
    def test_generic_container_tmp_is_noexec(self) -> None:
        wrapper = SCRIPT.parent / "wunder-devtools-ee.sh"
        self.assertIn(
            '--tmpfs "/tmp:rw,nosuid,nodev,noexec,size=2g"',
            wrapper.read_text(encoding="utf-8"),
        )

    def test_terraform_repository_requires_terraform_cli(self) -> None:
        module = load_repository_quality()
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "main.tf").write_text("terraform {}\n", encoding="utf-8")
            module.ROOT = root
            with (
                mock.patch.object(module, "shutil_which", return_value=None),
                self.assertRaisesRegex(
                    AssertionError,
                    "Terraform CLI is required",
                ),
            ):
                module.check_terraform("terraform_module")

    def test_external_command_timeout_fails_closed(self) -> None:
        module = load_repository_quality()
        timeout = module.EXTERNAL_COMMAND_TIMEOUT_SECONDS
        with (
            mock.patch.object(
                module.subprocess,
                "run",
                side_effect=subprocess.TimeoutExpired(["terraform", "version"], timeout),
            ),
            self.assertRaisesRegex(AssertionError, "timed out after"),
        ):
            module.run(["terraform", "version"])

    def test_required_command_disappearing_fails_closed(self) -> None:
        module = load_repository_quality()
        with (
            mock.patch.object(
                module.subprocess,
                "run",
                side_effect=FileNotFoundError("terraform"),
            ),
            self.assertRaisesRegex(
                AssertionError,
                "Required command not found: terraform",
            ),
        ):
            module.run(["terraform", "version"])

    def test_external_command_output_uses_deterministic_decoding(self) -> None:
        module = load_repository_quality()
        completed = subprocess.CompletedProcess(["terraform", "version"], 0)
        with mock.patch.object(
            module.subprocess,
            "run",
            return_value=completed,
        ) as run:
            module.run(["terraform", "version"])

        run.assert_called_once_with(
            ["terraform", "version"],
            cwd=module.ROOT,
            text=True,
            encoding="utf-8",
            errors="replace",
            capture_output=True,
            timeout=module.EXTERNAL_COMMAND_TIMEOUT_SECONDS,
        )


if __name__ == "__main__":
    unittest.main()
